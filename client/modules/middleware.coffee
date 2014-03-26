
# # Middleware

pkgman = require 'pkgman'

# ## Middleware
# 
# Implements a middleware stack. middleware functions can be added to the
# stack with `use`. Calling `dispatch` invokes the middleware functions
# serially.
# 
# Each middleware takes three parameters: `req`, `res`, and `next`. When a
# middleware finishes, it must call the `next` function. If there was an error,
# it must be thrown or passed as the first argument to `next`. If no error
# occurred, `next` must be invoked without arguments.
# 
# Error-handling middleware can also be defined. These middleware take four
# parameters: `error`, `req`, `res`, `next`. Error-handling middleware are only
# called if a previous middleware threw or passed an error. Conversely,
# non-error-handling middleware are skipped if a previous error occurred.
exports.Middleware = class Middleware
	
	# ## *constructor*
	# 
	# *Create a middleware stack.*
	constructor: ->
		
		@_middleware = []
	
	# ## ::use
	# 
	# *Add a middleware function to the stack.*
	# 
	# * (function) `fn` - A middleware function. 
	use: (fn) -> @_middleware.push fn
	
	# ## ::dispatch
	# 
	# *Invoke the middleware functions serially.*
	# 
	# * (object) `request` - A request object. 
	# 
	# * (mixed) `response` - A response object. Can be null. 
	# 
	# * (function) `fn` - A function invoked when the middleware stack has
	#   finished. If an error occurred, it will be passed as the first
	#   argument. 
	dispatch: (request, response, fn) ->
		
		index = 0
		
		invoke = (error) =>
			
			# Call `fn` with any error if we're done.
			return fn error if index is @_middleware.length
			
			current = @_middleware[index++]
			
			# Error-handling middleware.
			if current.length is 4
				
				# An error occurred previously.
				if error?
					
					# Try to invoke the middleware, if it throws, just catch
					# the error and pass it along.
					try
						current error, request, response, (error) ->
							invoke error
					catch error
						invoke error
					
				# No previous error; skip this middleware.
				else
					
					invoke error
					
			# Non-error-handling middleware.
			else
				
				# An error occurred previously, skip this middleware.
				if error?
					
					invoke error
				
				# No previous error.
				else
				
					# Try to invoke the middleware, if it throws, just catch
					# the error and pass it along.
					try
						current request, response, (error) -> invoke error
					catch error
						invoke error

		# Kick things off.
		invoke()

# ## fromHook
# 
# Create a middleware stack from the results of a hook and path configuration.
exports.fromHook = (hook, paths, args...) ->
	
	middleware = new Middleware

	# Invoke the hook and `use` the middleware in the paths configuration
	# order.
	args.unshift hook
	hookResults = pkgman.invoke args...
	for path in paths
		middleware.use _ for _ in hookResults[path]?.middleware ? []
	
	middleware
