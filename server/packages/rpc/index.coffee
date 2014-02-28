
_ = require 'underscore'
errors = require 'errors'
pkgman = require 'pkgman'

exports.$socketMiddleware = ->
	
	# Gather all endpoints.
	endpoints = {}
	pkgman.invoke 'endpoint', (path, endpoint) ->
		
		endpoint = receiver: endpoint if _.isFunction endpoint
		endpoints["#{endpoint.route ? path.replace /\//g, '.'}"] = endpoint
	
	label: 'Receive and dispatch RPC calls'
	middleware: [
		
		(req, res, next) ->
			
			for route, endpoint of endpoints
				do (endpoint) ->
					
					req.socket.on "rpc://#{route}", (data, fn) ->
						
						req.session?.touch()
						req.body = data
						
						endpoint.receiver(
							req, (error, result) ->
								reply = (sError) ->
									return fn error: errors.serialize sError if sError?
									return fn error: errors.serialize error if error?
									
									fn result: result
								
								session = req.session
								if session?
									session.save reply
								else
									reply()
						)
						
			next()
			
	]
