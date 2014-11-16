
# # AbstractHttp

Promise = require 'bluebird'

config = require 'config'
pkgman = require 'pkgman'
Promise = require 'bluebird'

middleware = require 'middleware'

httpDebug = require('debug') 'shrub:http'
httpMiddlewareDebug = require('debug') 'shrub:http:middleware'

# ## HttpManager
# 
# An abstract interface to be implemented by an HTTP server (e.g.
# [Express](./packages/http/Express.html)).
exports.Manager = class HttpManager

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
	
	# ### ::listen
	# 
	# *Listen for HTTP connections.*
	listen: ->
		
		new Promise (resolve, reject) =>
		
			do tryListener = =>
		
				@listener().done(
					resolve
					
					(error) ->
						return reject error unless 'EADDRINUSE' is error.code
					
						httpDebug "HTTP port in use... retrying in 2 seconds"
						setTimeout tryListener, 2000
						
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
		
		httpMiddlewareDebug '- Loading HTTP middleware...'
		
		httpMiddleware = @_config.middleware.slice 0
		httpMiddleware.push 'shrub-http'
		
		# Invoke hook `httpMiddleware`.
		# Invoked every time an HTTP connection is established.
		# `TODO`: Rename express to http, so we can use a short name.
		@_middleware = middleware.fromHook(
			'httpMiddleware', httpMiddleware, this
		)
		
		httpMiddlewareDebug '- HTTP middleware loaded.'

	# } Ensure any subclass implements these methods.
	@::[method] = (-> throw new ReferenceError(
		"HttpManager::#{method} is a pure virtual method!"

	# "Pure virtual" methods.
	)) for method in [
		
		'listener', 'server'
	]
