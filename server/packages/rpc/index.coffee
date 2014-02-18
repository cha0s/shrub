
_ = require 'underscore'
contexts = require 'contexts'
pkgman = require 'pkgman'

exports.$endpoint =
	
	route: 'hangup'
	receiver: (req, fn) ->
		
		return fn() unless (context = contexts.lookup req.session.id)?
		context.close fn

exports.$socketMiddleware = (http) ->
	
	# Gather all endpoints.
	endpoints = {}
	pkgman.invoke 'endpoint', (path, endpoint) ->
		
		endpoint = receiver: endpoint if _.isFunction endpoint
		endpoints["#{endpoint.route ? path.replace '/', '.'}"] = endpoint
	
	label: 'Receive and dispatch RPC calls'
	middleware: [
		
		(req, res, next) ->
			
			for route, endpoint of endpoints
				do (endpoint) ->
					
					req.socket.on "rpc://#{route}", (data, fn) ->
						
						req.session?.touch()
						req.body = data
						
						endpoint.receiver(
							req, (errors, result) ->
								reply = ->
									return fn result: result unless errors?
									
									errors = [errors] unless Array.isArray errors
									fn errors: errors, result: result
								
								session = req.session
								if session?
									session.save reply
								else
									reply()
						)
						
			next()
			
	]
