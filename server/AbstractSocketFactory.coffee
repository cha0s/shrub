
# # AbstractSocketFactory
# 
# This class implements an abstract interface to be implemented by a socket
# server (e.g. [Socket.io](./packages/socket/SocketIo.html)).
# 
# `TODO`: This needs work, it probably wouldn't be able to handle another
# server in its current state. Move API from SocketIo to here.

{EventEmitter} = require 'events'
pkgman = require 'pkgman'

middleware = require 'middleware'

{defaultLogger} = require 'logging'

module.exports = class AbstractSocketFactory extends EventEmitter
	
	# ### *constructor*
	# 
	# *Create the server.*
	# 
	# * (object) `config` - The server configuration.
	#   `TODO`: Should probably just use `nconf`, weird interface.
	constructor: (@_config) ->
		super
	
	# `AbstractSocketFactory.AuthorizationFailure` may be thrown from within
	# socket authorization middleware, to denote that no real error occurred,
	# authorization just failed.
	class @AuthorizationFailure extends Error
		constructor: (@message) ->
	
	# ### .loadMiddleware
	# 
	# *Gather and initialize socket middleware.*
	loadMiddleware: ->
		
		# Invoke hook `socketAuthorizationMiddleware`.
		# Allows packages to determine whether a socket connection is
		# authorized.
		defaultLogger.info 'BEGIN loading socket authorization middleware'
		@_authorizationMiddleware = middleware.fromHook(
			'socketAuthorizationMiddleware'
			@_config.authorizationMiddleware
		)
		defaultLogger.info 'END loading socket authorization middleware'

		# Invoke hook `socketRequestMiddleware`.
		# Allows packages to run behavior for every socket connection.
		defaultLogger.info 'BEGIN loading socket middleware'
		@_requestMiddleware = middleware.fromHook(
			'socketRequestMiddleware'
			@_config.requestMiddleware
		)
		defaultLogger.info 'END loading socket middleware'

	# } Ensure any subclass implements these methods.
	@::[method] = (-> throw new ReferenceError(
		"AbstractSocket::#{method} is a pure virtual method!"

	# "Pure virtual" methods.
	)) for method in [
		
		'listen', 'socketsInChannel'
	]