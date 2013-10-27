
path = require 'path'
walk = require 'walk'
Q = require 'q'
winston = require 'winston'

# Gather all endpoints.
endpoints = {}
base = path.join __dirname, 'endpoints'

walker = walk.walk base 
walker.on 'file', (root, fileStats, next) ->
	
	extname = path.extname fileStats.name
	basename = path.basename fileStats.name, extname
	basename = '' if basename is 'index'
	relativeBase = root.substr base.length + 1
	
	key = (path.join relativeBase, basename).replace /[\/\\]/, '.'
	endpoint = require path.join base, relativeBase, basename
	
	endpoints[key] = endpoint
	
	next()
	
walker.on 'end', -> winston.info 'RPC endpoints loaded'

module.exports.middleware = -> [
	
	(req, res, next) ->
		
		for route, endpoint of endpoints
			do (endpoint) ->
				req.socket.on "rpc://#{route}", (data, fn) ->
					
					req.session?.touch()
					
					endpoint(
						req, data
						(errors, result) ->
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
