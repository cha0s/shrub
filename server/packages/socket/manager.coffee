
# # SocketManager

{EventEmitter} = require 'events'
nconf = require 'nconf'

middleware = require 'middleware'
pkgman = require 'pkgman'

{defaultLogger} = require 'logging'

# This class implements an abstract interface to be implemented by a socket
# server (e.g. [Socket.io](./packages/socket/SocketIo.html)).
module.exports = class SocketManager extends EventEmitter
	
	# ### *constructor*
	# 
	# *Create the server.*
	constructor: ->
		
		super
		
		@_authorizationMiddleware = null
		@_connectionMiddleware = null
	
	# `SocketManager.AuthorizationFailure` may be thrown from within socket
	# authorization middleware, to denote that no real error occurred,
	# authorization just failed.
	class @AuthorizationFailure extends Error
		constructor: (@message) ->
	
	# ### .loadMiddleware
	# 
	# *Gather and initialize socket middleware.*
	loadMiddleware: ->
		
		config = nconf.get 'packageSettings:socket'
		
		# Invoke hook `socketAuthorizationMiddleware`.
		# Invoked when a socket connection begins. Packages may throw an
		# instance of `SocketManager.AuthorizationFailure` to reject
		# the socket connection as unauthorized.
		defaultLogger.info 'Loading socket authorization middleware...'
		@_authorizationMiddleware = middleware.fromHook(
			'socketAuthorizationMiddleware'
			config.authorizationMiddleware
		)
		defaultLogger.info 'Socket authorization middleware loaded.'

		# Invoke hook `socketConnectionMiddleware`.
		# Invoked for every socket connection.
		defaultLogger.info 'Loading socket middleware...'

		@_connectionMiddleware = middleware.fromHook(
			'socketConnectionMiddleware'
			config.connectionMiddleware
		)
		defaultLogger.info 'Socket middleware loaded.'

	# } Ensure any subclass implements these methods.
	@::[method] = (-> throw new ReferenceError(
		"AbstractSocket::#{method} is a pure virtual method!"

	# "Pure virtual" methods.
	)) for method in [
		
		'channelsSocketIsIn', 'listen', 'socketsInChannel'
	]
