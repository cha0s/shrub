
exports.Middleware = Middleware = class
	
	constructor: ->
		
		@_dispatcher = ->
		@_middleware = []
	
	use: (fn) -> @_middleware.push fn
	
	dispatch: (request, response, fn) ->
		
		index = 0
		
		domain = (require 'domain').create()
		domain.enter()
		domain.on 'error', fn
		
		invoke = (error) =>
			
			if index is @_middleware.length
				domain.exit()
				return fn error
			
			current = @_middleware[index]
			index += 1
			
			if current.length is 4
				
				if error?
					
					current error, request, response, (error) -> invoke error
					
				else
					
					invoke error
					
			else
				
				if error?
					
					invoke error
				
				else
				
					current request, response, (error) -> invoke error
				
		invoke null
