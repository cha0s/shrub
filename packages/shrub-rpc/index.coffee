
# # RPC
# 
# Framework for communication between client and server through
# [RPC](http://en.wikipedia.org/wiki/Remote_procedure_call#Message_passing)

_ = require 'underscore'
debug = require('debug') 'shrub:rpc'
Promise = require 'bluebird'

config = require 'config'

audit = require 'audit'
errors = require 'errors'
logging = require 'logging'
pkgman = require 'pkgman'

logger = logging.create 'logs/rpc.log'

{Limiter} = require 'limits'
{Middleware} = require 'middleware'
{TransmittableError} = errors

clientModule = require './client'

# RPC endpoint information.
endpoints = {}

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `initialize`
	registrar.registerHook 'initialize', ->
	
		# A route is defined like:
		# 
		# * `validators`: Validators are run before the call is received. They are
		#   defined as middleware.
		# 
		# * `receiver`: The receiver is called if none of the validators throw an
		#   error.
		# 
		# Example:
		validators: [
			
			(req, res, next) ->
				
				if req.badStuffHappened
					
					next new Error "YIKES!"
					
				else
					
					next()
		]
		
		receiver: (req, fn) ->
		
			if req.badStuffHappened
				
				fn new Error "YIKES!"
				
			else
				
				# Anything you pass to the second parameter of fn will be passed
				# back to the client. Keep this in mind.
				fn null, message: "Everything went better than expected!"
				
		# Invoke hook `endpoint`.
		# Gather all endpoints.
		debug '- Registering RPC endpoints...'
		for path, endpoint of pkgman.invoke 'endpoint'
			
			endpoint = receiver: endpoint if _.isFunction endpoint
			
			# Default the RPC route to the package path, replacing slashes with
			# dots.
			endpoint.route ?= clientModule.normalizeRouteName path
			debug "- - rpc://#{endpoint.route}"
			
			endpoint.validators ?= []
			
			endpoints[endpoint.route] = endpoint
		debug '- RPC endpoints registered.'
		
		# Invoke hook `endpointAlter`.
		# Allows packages to modify any endpoints defined.
		pkgman.invoke 'endpointAlter', endpoints
		
		# Set up the validators as middleware.
		for route, endpoint of endpoints
		
			validators = new Middleware()
			validators.use validator for validator in endpoint.validators
			endpoint.validators = validators
			
	# ## Implements hook `socketConnectionMiddleware`
	registrar.registerHook 'socketConnectionMiddleware', ->
		
		label: 'Receive and dispatch RPC calls'
		middleware: [
			
			(req, res, next) ->
				
				Object.keys(endpoints).forEach (route) ->
					endpoint = endpoints[route]
					
					req.socket.on "rpc://#{route}", (data, fn) ->
						
						# Don't pass req directly, since it can be mutated by
						# routes, and violate other routes' expectations.
						routeReq = {}
						routeReq[key] = value for key, value of req
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
						sendErrorToClient = (error) ->
							emitError error
							
							# Log the full error stack, because it might help
							# track down any problem.
							logError error if do -> 
								
								# Unknown errors.
								unless error instanceof TransmittableError
									return true
								
								# If we're not running in production. 
								if 'production' isnt config.get 'NODE_ENV'
									return true
							
						# Validate.
						endpoint.validators.dispatch routeReq, null, (error) ->
							return sendErrorToClient error if error?
							
							# Receive.
							endpoint.receiver routeReq, (error, result) ->
								return sendErrorToClient error if error?
								
								# Invoke hook `endpointFinished`.
								# Allow packages to act after an RPC call, but
								# before the response is sent. Packages may
								# modify the response before it is returned.
								# Implementations should return a promise. When
								# all promises are resolved, the result is
								# returned.
								Promise.all(
									pkgman.invokeFlat(
										'endpointFinished', routeReq, result, req
									)							
	
								).then(
									-> fn result: result
									concealErrorFromClient
								)
									
				next()
				
		]
