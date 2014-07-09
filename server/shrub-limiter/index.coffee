
# # Rate limiter
# 
# Limits the rate at which clients can do certain operations, like call RPC
# endpoints.

moment = require 'moment'
Promise = require 'bluebird'

audit = require 'audit'
errors = require 'errors'

{Limiter, threshold} = require 'limits'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `endpointAlter`
	# 
	# Allow RPC endpoint definitions to specify rate limiters.
	registrar.registerHook 'endpointAlter', (endpoints) ->
	
		# A limiter on a route is defined like:
		# 
		# * `message`: The message returned to the client when the threshold is
		#   passed.
		# 
		# * `threshold`: The
		#   [threshold](http://shrub.doc.com.dev/server/limits.html#threshold) for
		#   this limiter.
		# 
		# * `ignoreKeys`: The
		#   [audit keys](http://shrub.doc.com.dev/hooks.html#fingerprint) to ignore
		#   when determining the total limit. In this example, the IP address and
		#   session ID would be ignored.
		
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
			endpoint.limiter.ignoreKeys ?= []
			endpoint.limiter.message ?= "You are doing that too much."
			
			# Add a validator, where we'll check the threshold.
			endpoint.validators.push (req, res, next) ->
				
				{ignoreKeys, instance, message, threshold} = endpoint.limiter
				
				# Ignore keys.
				fingerprint = audit.fingerprint req
				delete fingerprint[excludedKey] for excludedKey in ignoreKeys
				
				# Accrue a hit and check the threshold.
				keys = ("#{key}:#{value}" for key, value of fingerprint)
				instance.accrueAndCheckThreshold(keys).then((isLimited) ->
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
				
	# ## Implements hook `transmittableError`
	# 
	# Just defer to client, where the error is defined.
	registrar.registerHook 'transmittableError', require('client/modules/shrub-limiter').transmittableError
