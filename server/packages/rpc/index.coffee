
# # RPC
# 
# Framework for communication between client and server through
# [RPC](http://en.wikipedia.org/wiki/Remote_procedure_call#Message_passing)

_ = require 'underscore'
Promise = require 'bluebird'

audit = require 'audit'
errors = require 'errors'
logging = require 'logging'
pkgman = require 'pkgman'

logger = logging.create 'logs/rpc.log'

{Limiter} = require 'limits'
{Middleware} = require 'middleware'

# RPC endpoint information.
endpoints = {}

# An example of defining an endpoint:
exports.$endpoint = ->
	
	# Validators can be run before the call is received. They are defined as
	# middleware.
	validators: [
		
		(req, res, next) ->
			
			if req.badStuffHappened
				
				next new Error "YIKES!"
				
			else
				
				next()
	]
	
	# The receiver is called if none of the validators throw an error.
	receiver: (req, fn) ->
	
		if req.badStuffHappened
			
			fn new Error "YIKES!"
			
		else
			
			# Anything you pass to the second parameter of fn will be passed
			# back to the client. Keep this in mind.
			fn null, message: "Everything went better than expected!"
			
	# } ... the rest of the endpoint definition
	
# } ...that was just an example.
delete exports.$endpoint

# ## Implements hook `initialize`
exports.$initialize = ->

	# Invoke hook `endpoint`.
	# Gather all endpoints.
	for path, endpoint of pkgman.invoke 'endpoint'
		
		endpoint = receiver: endpoint if _.isFunction endpoint
		
		# Default the RPC route to the package path, replacing slashes with
		# dots.
		endpoint.route ?= endpoint.route ? path.replace /\//g, '.'
		endpoint.validators ?= []
		
		endpoints[endpoint.route] = endpoint
	
	# Invoke hook `endpointAlter`.
	# Allows packages to modify any endpoints defined.
	pkgman.invoke 'endpointAlter', endpoints
	
	# Set up the validators as middleware.
	for route, endpoint of endpoints
	
		validators = new Middleware()
		validators.use validator for validator in endpoint.validators
		endpoint.validators = validators
		
# ## Implements hook `socketConnectionMiddleware`
exports.$socketConnectionMiddleware = ->
	
	label: 'Receive and dispatch RPC calls'
	middleware: [
		
		(req, res, next) ->
			
			Object.keys(endpoints).forEach (route) ->
				endpoint = endpoints[route]
				
				req.socket.on "rpc://#{route}", (data, fn) ->
					
					# Don't pass req directly, since it can be mutated by
					# routes, and violate other routes' expectations.
					routeReq = {}
					routeReq[key] = value for own key, value of req
					routeReq.body = data
					
					# } Send an error to the client.
					emitError = (error) -> fn error: errors.serialize error
					
					# } Log an error without transmitting it.
					logError = (error) -> logger.error errors.stack error
					
					# Send an error to the client, but don't notify them of
					# the real underlying issue.
					concealErrorFromClient = (error) ->
						
						emitError new Error "Please try again later."
						logError error
						
					# Transmit the error as it is directly to the client.
					sendErrorToClient = (error) -> emitError error
					
					# Validate.
					endpoint.validators.dispatch routeReq, null, (error) ->
						return sendErrorToClient error if error?
						
						# Receive.
						endpoint.receiver routeReq, (error, result) ->
							return sendErrorToClient error if error?
							
							# Touch and save the session for every RPC call.
							# `TODO`: Should be middleware for after a request,
							# `session` should register into that.
							reply = (error) ->
								return concealErrorFromClient(
									error
								) if error?
								
								fn result: result
							
							if (session = req.session)?
								session.touch().save reply
							else
								reply()
					
			next()
			
	]
