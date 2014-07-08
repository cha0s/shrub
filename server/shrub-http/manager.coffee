
# # AbstractHttp

Promise = require 'bluebird'

config = require 'config'
pkgman = require 'pkgman'

{defaultLogger} = require 'logging'

middleware = require 'middleware'

# ## HttpManager
# 
# An abstract interface to be implemented by an HTTP server (e.g.
# [Express](./packages/http/Express.html)).
module.exports = class HttpManager

	# ### *constructor*
	# 
	# *Create the server.*
	constructor: ->
		
		@_config = config.get 'packageSettings:shrub-http'
		
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
			
	# ### ::path
	# 
	# *The path where static files are served from.*
	path: -> @_config.path
	
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

	# } Ensure any subclass implements these methods.
	@::[method] = (-> throw new ReferenceError(
		"HttpManager::#{method} is a pure virtual method!"

	# "Pure virtual" methods.
	)) for method in [
		
		'listen', 'renderAppHtml', 'server'
	]
