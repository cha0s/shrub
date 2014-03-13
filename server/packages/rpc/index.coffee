
_ = require 'underscore'
Promise = require 'bluebird'

audit = require 'audit'
errors = require 'errors'
pkgman = require 'pkgman'

{Limiter} = require 'limits'

exports.$socketMiddleware = ->
	
	# Gather all endpoints.
	endpoints = {}
	pkgman.invoke 'endpoint', (path, endpoint) ->
		
		endpoint = receiver: endpoint if _.isFunction endpoint
		
		endpoint.route ?= endpoint.route ? path.replace /\//g, '.'
		
		if endpoint.threshold?
			
			endpoint.limiter = new Limiter(
				"rpc://#{endpoint.route}"
				endpoint.threshold
			)
				
			endpoint.message ?= "You are doing that too much."
			
		endpoints[endpoint.route] = endpoint
	
	pkgman.invoke 'endpointAlter', (_, fn) -> fn endpoints
		
	label: 'Receive and dispatch RPC calls'
	middleware: [
		
		(req, res, next) ->
			
			for route, endpoint of endpoints
				
				do (route, endpoint) ->
				
					uri = "rpc://#{route}"
					req.socket.on uri, (data, fn) ->
						
						req.session?.touch()
						req.body = data
						
						concealErrorFromClient = (error) ->
							errors.caught error
							fn error: errors.serialize new Error(
								"Please try again later."
							)
							next error
							
						returnErrorToClient = (error) ->
							errors.caught error
							fn error: errors.serialize error
							
						limitPromise = if endpoint.limiter?
							
							endpoint.limiter.addAndCheckThreshold(
								audit.keys req
							)
							
						else
							
							Promise.resolve false 
						
						limitPromise.done(

							(isLimited) ->
								
								return endpoint.receiver(
									req, (error, result) ->
										returnErrorToClient error if error?
										
										reply = (error) ->
											return concealErrorFromClient(
												error
											) if error?
											
											fn result: result
										
										session = req.session
										if session?
											session.save reply
										else
											reply()
								) unless isLimited
								
								error = errors.instantiate(
									'limiterThreshold'
									endpoint.message
									endpoint.threshold.time()
								)
								
								return returnErrorToClient error
						
							(error) -> concealErrorFromClient error
						)
						
			next()
			
	]
