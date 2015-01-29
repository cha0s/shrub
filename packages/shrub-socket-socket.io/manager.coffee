# ## SocketIoManager
# Implements `SocketManager`.
#
# A socket factory implemented with [Socket.IO](http://socket.io/).
config = require 'config'

SocketManager = require '../shrub-socket/manager'
{AuthorizationFailure} = SocketManager

module.exports = class SocketIoManager extends SocketManager

	# ## *constructor*
	constructor: ->
		super

		options = config.get 'packageSettings:shrub-socket:manager:options'

		# Load the adapter.
		@_adapter = switch options?.store ? 'redis'

			when 'redis'

				redis = require 'redis'

				require('socket.io-redis')(
					pubClient: redis.createClient()
					subClient: redis.createClient()
				)

	# ## ::channels
	#
	# *Get a list of channels a socket is in.*
	#
	# * (string) `room` - The channel to broadcast to.
	# * (mixed) `data` - The data to broadcast.
	broadcast: (room, event, data) ->
		@io.in(room).emit event, data
		this

	# ## ::channels
	#
	# *Get a list of channels a socket is in.*
	#
	# * (socket) `socket` - A socket.
	channels: (socket) -> socket.rooms

	# ## ::listen
	# Implements `SocketManager::listen`.
	listen: (http) ->

		options = config.get 'packageSettings:shrub-socket:manager:options'

		# Set up the socket.io server.
		@io = require('socket.io') http.server()

		# Set the adapter.
		@io.adapter @_adapter if @_adapter?

		# Authorization.
		@io.use (socket, next) =>

			socket.request.http = http
			socket.request.socket = socket

			# Dispatch the authorization middleware.
			@_authorizationMiddleware.dispatch socket.request, null, (error) ->

				# If any kind of error was thrown, propagate it.
				return next error if error?

				next()

		# Connection (post-authorization).
		@io.on 'connection', (socket) =>

			# Run the disconnection middleware on socket close.
			oncloseProxy = socket.onclose
			socket.onclose = =>
				@_disconnectionMiddleware.dispatch socket.request, null, (error) ->
					return logger.error errors.stack error if error?

				oncloseProxy.call socket

			# Join a '$global' channel.
			socket.join '$global', (error) =>
				return logger.error errors.stack error if error?

				# Dispatch the connection middleware.
				@_connectionMiddleware.dispatch socket.request, null, (error) ->
					return logger.error errors.stack error if error?

					socket.emit 'initialized'

	# ## ::socketsInChannel
	#
	# *Get a list of sockets in a channel.*
	#
	# `TODO`: This only works on a single node. socket.io needs to implement
	# this.
	#
	# * (string) `channelName` - The channel or 'room' name.
	socketsInChannel: (channelName) ->

		for socketId, isConnected of @io.sockets.adapter.rooms[channelName]
			continue unless isConnected

			@io.sockets.adapter.nsp.connected[socketId]
