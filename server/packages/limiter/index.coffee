
# # Rate limiter
# 
# Limits the rate at which clients can do certain operations, like call RPC
# endpoints.

moment = require 'moment'
Promise = require 'bluebird'

audit = require 'audit'
errors = require 'errors'

{Limiter, threshold} = require 'limits'

# An example of defining a limiter on an endpoint:
exports.$endpoint = ->

	limiter:
	
		# The message returned to the client when the threshold is passed.
		message: "Too many things!"
	
		# The [threshold](http://shrub.doc.com.dev/server/limits.html#threshold)
		# for this limiter.
		threshold: threshold(3).every(30).seconds()
	
		# The [audit keys](http://shrub.doc.com.dev/hooks.html#auditkeys)
		# to ignore when determining the total limit. In this example, the
		# IP address and session ID would be ignored.
		excludeKeys: ['ip', 'session']
		
	# } ... the rest of the endpoint definition
	
# } ...that was just an example.
delete exports.$endpoint

# ## Implements hook `endpointAlter`
# 
# Allow RPC endpoint definitions to specify rate limiters.
exports.$endpointAlter = (endpoints) ->

	Object.keys(endpoints).forEach (route) ->
		endpoint = endpoints[route]
		
		# } No limter? Nevermind...
		return unless endpoint.limiter?
		
		# Create a limiter based on the threshold defined.
		endpoint.limiter.instance = new Limiter(
			"rpc://#{route}"
			endpoint.limiter.threshold
		)
		
		# Set defaults.
		# `TODO`: Rename to `ignoreKeys`.
		endpoint.limiter.excludeKeys ?= []
		endpoint.limiter.message ?= "You are doing that too much."
		
		# Add a validator, where we'll check the threshold.
		endpoint.validators.push (req, res, next) ->
			
			{excludeKeys, instance, message, threshold} = endpoint.limiter
			
			# Ignore keys.
			auditKeys = audit.keys req
			delete auditKeys[excludedKey] for excludedKey in excludeKeys
			
			# Accrue a hit and check the threshold.
			keys = ("#{key}:#{value}" for key, value of auditKeys)
			instance.addAndCheckThreshold(keys).then((isLimited) ->
				return next() unless isLimited
				
				# Report villiany for crossing the limiter threshold.
				# `TODO`: Should this be added by [villiany](/server/packages/villiany/index.html)?
				promise = if req.reportVilliany?
				
					req.reportVilliany(
						endpoint.villianyScore ? 20
						"rpc://#{route}:limiter"
					)
					
				else
					
					Promise.resolve false
				
				promise.then (isVillian) ->
					return if isVillian
					
					# Build a nice error message for the client, so they
					# hopefully will stop doing that.
					instance.ttl(keys).then (ttl) ->
					
						next errors.instantiate(
							'limiterThreshold'
							message
							moment().add('seconds', ttl).fromNow()
						)
					
			).catch next
			
# ## Implements hook `errorType`
# 
# Just defer to client, where the error is defined.
exports.$errorType = require('client/modules/packages/limiter').$errorType
