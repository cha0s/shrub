
# # AbstractHttp

nconf = require 'nconf'
pkgman = require 'pkgman'
Promise = require 'bluebird'

{defaultLogger} = require 'logging'

middleware = require 'middleware'

# ## AbstractHttp
# 
# An abstract interface to be implemented by an HTTP server (e.g.
# [Express](./packages/express/index.html)).
# 
# `TODO`: This needs work, it probably wouldn't be able to handle another
# server in its current state. Move API from Express to here, and use a
# 'pure virtual' pattern, to allow any other server to extend along reasonable
# lines.
module.exports = class AbstractHttp

	# ### *constructor*
	# 
	# *Create the server.*
	# 
	# * (object) `config` - The server configuration.
	#   `TODO`: Should probably just use nconf, weird interface.
	constructor: (@_config) ->
		
		@_middleware = null
	
	# ### .initialize
	# 
	# *Initialize the server.*
	# 
	# * (function) `fn` - The function to be called upon initialization.
	initialize: (fn) ->
		
		# Invoke hook `httpInitializer`.
		# Invoked before the server is bound on the listening port.
		# 
		# } `TODO`: This invocation should probably be middleware.fromHook()'d
		initializerMiddleware = new middleware.Middleware()

		# } `TODO`: Rename to `httpStarting`.
		for fn_ in pkgman.invokeFlat 'httpInitializer'
			initializerMiddleware.use fn_
		
		# } Dispatch the middleware.
		request = http: this
		response = null
		initializerMiddleware.dispatch request, response, (error) =>
			return fn error if error?
			
			# Start listening.
			@listen (error) =>
				return fn error if error?
				
				Promise.all(
					
					# Invoke hook `httpListening`.
					# Invoked once the server is listening, but before
					# initialization finishes.
					pkgman.invokeFlat 'httpListening', this
				
				# Finish initialization.
				).then(
					-> fn()
					(error) -> fn error
				)
		
	# ### .config
	# 
	# *Get the server configuration.*
	config: -> @_config
		
	# ### .port
	# 
	# *Get the port this server (is|will be) listening on.*
	port: -> @_config.port
		
	# ### .registerMiddleware
	# 
	# *Gather and initialize HTTP middleware.*
	registerMiddleware: ->
		
		defaultLogger.info 'BEGIN loading HTTP middleware'
		
		# Invoke hook `httpMiddleware`.
		# Invoked every time an HTTP connection is established.
		@_middleware = middleware.fromHook(
			'httpMiddleware'
			@_config.middleware
			this
		)
		
		defaultLogger.info 'END loading HTTP middleware'
