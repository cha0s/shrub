# ## SocketIoManager
# Implements `SocketManager`.
#
# A socket factory implemented with [Socket.IO](http://socket.io/).

Promise = null

config = null

SocketManager = require '../shrub-socket/manager'

module.exports = class SocketIoManager extends SocketManager

	# ## *constructor*
	constructor: ->
		super

		Promise = require 'bluebird'

		config ?= require 'config'

		options = config.get 'packageSettings:shrub-socket:manager:options'

		# Load the adapter.
		@_adapter = switch options?.store ? 'redis'

			when 'redis'

				redis = require 'redis'

				require('socket.io-redis')(
					pubClient: redis.createClient()
					subClient: redis.createClient()
				)

	# ## ::broadcast
	#
	# *Broadcast data to clients in a room.*
	#
	# * (string) `channel` - The channel to broadcast to.
	# * (string) `event` - The event to broadcast.
	# * (mixed) `data` - The data to broadcast.
	broadcast: (channel, event, data) ->
		@io.in(channel).emit event, data
		this

	# ## ::channels
	#
	# *Get a list of channels a socket is in.*
	#
	# * (socket) `socket` - A socket.
	channels: (socket) -> socket.rooms

	# ## ::clients
	#
	# *Get a list of clients in a channel.*
	#
	# * (string) `channel` - The channel to check.
	clients: (channel) ->
		self = this
		new Promise (resolve, reject) ->
			self.io.in(channel).clients (error, clients) ->
				return reject error if error?
				resolve clients

	# ## ::intercom
	#
	# *Broadcast data to server sockets in a room.*
	#
	# * (string) `channel` - The channel to broadcast to.
	# * (string) `event` - The event to broadcast.
	# * (mixed) `data` - The data to broadcast.
	intercom: (channel, event, data) ->
		@io.in(channel).intercom event, data
		this

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
