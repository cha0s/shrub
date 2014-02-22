
pkgman = require 'pkgman'

exports.Middleware = class Middleware
	
	constructor: ->
		
		@_dispatcher = ->
		@_middleware = []
	
	use: (fn) -> @_middleware.push fn
	
	dispatch: (request, response, fn) ->
		
		index = 0
		
		invoke = (error) =>
			
			return fn error if index is @_middleware.length
			
			current = @_middleware[index]
			index += 1
			
			if current.length is 4
				
				if error?
					
					try
					
						current error, request, response, (error) -> invoke error
					
					catch error
					
						invoke error
					
				else
					
					invoke error
					
			else
				
				if error?
					
					invoke error
				
				else
				
					try
					
						current request, response, (error) -> invoke error
					
					catch error
					
						invoke error

		invoke null

exports.fromHook = (hook, paths, fn) ->

	hookResults = {}
	pkgman.invoke hook, (path, spec) -> hookResults[path] = spec
		
	middleware = new Middleware
	
	for path in paths
		continue unless (spec = fn path, hookResults[path])?
		
		middleware.use _ for _ in spec.middleware
	
	middleware
