
exports.Middleware = Middleware = class
	
	constructor: ->
		
		@_dispatcher = ->
		@_middleware = []
	
	use: (fn) -> @_middleware.push fn
	
	dispatch: (req, res, fn) ->
		
		index = 0
		
		invoke = (error) =>
			return fn error if index is @_middleware.length
			
			current = @_middleware[index]
			index += 1
			
			if current.length is 4
				
				if error?
					
					current error, req, res, (error) -> invoke error
					
				else
					
					invoke error
					
			else
				
				if error?
					
					invoke error
				
				else
				
					current req, res, (error) -> invoke error
				
		invoke null
