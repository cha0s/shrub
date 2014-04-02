
# # AbstractHttp

config = require 'config'
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
	#   `TODO`: Should probably just use config, weird interface.
	constructor: (@_config) ->
		
		@_middleware = null
	
	# ### .initialize
	# 
	# *Initialize the server.*
	initialize: ->
		
		# Invoke hook `httpInitializing`.
		# Invoked before the server is bound on the listening port.
		pkgman.invoke 'httpInitializing', this
		
		# Start listening.
		@listen().then => Promise.all(
				
			# Invoke hook `httpListening`.
			# Invoked once the server is listening, but before
			# initialization finishes. Implementations should return a
			# promise. When all promises are fulfilled, initialization
			# finishes.
			pkgman.invokeFlat 'httpListening', this
		
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
		
		defaultLogger.info 'Loading HTTP middleware...'
		
		# Invoke hook `httpMiddleware`.
		# Invoked every time an HTTP connection is established.
		# `TODO`: Rename express to http, so we can use a short name.
		@_middleware = middleware.fromHook(
			'httpMiddleware'
			@_config.middleware
			this
		)
		
		defaultLogger.info 'HTTP middleware loaded.'
