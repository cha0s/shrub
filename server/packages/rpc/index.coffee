
_ = require 'underscore'
Promise = require 'bluebird'
winston = require 'winston'

audit = require 'audit'
errors = require 'errors'
pkgman = require 'pkgman'

logger = new winston.Logger
	transports: [
		new winston.transports.Console level: 'error', colorize: true
		new winston.transports.File level: 'debug', filename: 'logs/rpc.log'
	]

{Limiter} = require 'limits'
{Middleware} = require 'middleware'

exports.$socketRequestMiddleware = ->
	
	# Gather all endpoints.
	endpoints = {}
	for path, endpoint of pkgman.invoke 'endpoint'
		
		endpoint = receiver: endpoint if _.isFunction endpoint
		
		endpoint.route ?= endpoint.route ? path.replace /\//g, '.'
		endpoint.validators ?= []
		
		endpoints[endpoint.route] = endpoint
	
	pkgman.invoke 'endpointAlter', endpoints
	
	for route, endpoint of endpoints
	
		validators = new Middleware()
		validators.use validator for validator in endpoint.validators
		endpoint.validators = validators
		
	label: 'Receive and dispatch RPC calls'
	middleware: [
		
		(req, res, next) ->
			
			for route, endpoint of endpoints
				
				do (route, endpoint) ->
				
					uri = "rpc://#{route}"
					req.socket.on uri, (data, fn) ->
						
						routeReq = {}
						routeReq[key] = value for own key, value of req
						
						routeReq.body = data
						
						emitError = (error) -> fn error: errors.serialize error
						
						logError = (error) -> logger.error errors.stack error
						
						concealErrorFromClient = (error) ->
							errors.caught error
							emitError new Error(
								"Please try again later."
							)
							logError error
							
						sendErrorToClient = (error) ->
							errors.caught error
							emitError error
						
						endpoint.validators.dispatch routeReq, null, (error) ->
							return sendErrorToClient error if error?
							
							endpoint.receiver(
								routeReq, (error, result) ->
									return sendErrorToClient error if error?
									
									reply = (error) ->
										return concealErrorFromClient(
											error
										) if error?
										
										fn result: result
									
									if (session = req.session)?
										session.touch().save reply
									else
										reply()
							)
						
			next()
			
	]
