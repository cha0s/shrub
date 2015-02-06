
# # SocketManager

{EventEmitter} = require 'events'

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
		@_disconnectionMiddleware = null

	# `SocketManager.AuthorizationFailure` may be thrown from within socket
	# authorization middleware, to denote that no real error occurred,
	# authorization just failed.
	class @AuthorizationFailure extends Error
		constructor: (@message) ->

	# ### .loadMiddleware
	#
	# *Gather and initialize socket middleware.*
	loadMiddleware: ->

		middleware = require 'middleware'

		# Invoke hook `socketAuthorizationMiddleware`.
		# Invoked when a socket connection begins. Packages may throw an
		# instance of `SocketManager.AuthorizationFailure` to reject
		# the socket connection as unauthorized.
		@_authorizationMiddleware = middleware.fromShortName(
			'socket authorization'
			'shrub-socket'
		)

		# Invoke hook `socketConnectionMiddleware`.
		# Invoked for every socket connection.
		@_connectionMiddleware = middleware.fromShortName(
			'socket connection'
			'shrub-socket'
		)

		# Invoke hook `socketDisconnectionMiddleware`.
		# Invoked when a socket disconnects.
		@_disconnectionMiddleware = middleware.fromShortName(
			'socket disconnection'
			'shrub-socket'
		)

	# } Ensure any subclass implements these methods.
	SocketManager::[method] = (-> throw new ReferenceError(
		"SocketManager::#{method} is a pure virtual method!"

	# "Pure virtual" methods.
	)) for method in [

		'broadcast', 'channels', 'listen'
	]
