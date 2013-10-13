
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
		
		touchSessionIfExists = ->
			deferred = Q.defer()
			
			if req.session?
				req.session.touch().save (error) ->
					return deferred.reject  error if error?
					deferred.resolve()
				
			else
				deferred.resolve()
			
			deferred.promise
		
		for route, endpoint of endpoints
			do (endpoint) ->
				req.socket.on route, ->
					args = [req].concat (arg for arg in arguments)
					touchSessionIfExists().then ->
						endpoint.apply null, args
					
		next()

]
