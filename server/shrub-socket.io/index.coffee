
# # Socket.IO
# 
# SocketManager implementation using [Socket.IO](http://socket.io/).

Promise = require 'bluebird'

config = require 'config'
errors = require 'errors'
logging = require 'logging'
pkgman = require 'pkgman'

logger = new logging.create 'logs/socket.io.log'
	
SocketManager = require '../shrub-socket/manager'
{AuthorizationFailure} = SocketManager

# ## SocketIoManager
# Implements `SocketManager`.
# 
# A socket factory implemented with [Socket.IO](http://socket.io/).
module.exports = class SocketIoManager extends SocketManager
	
	# ## *constructor*
	constructor: ->
		super
		
		options = config.get 'packageSettings:shrub-socket:manager:options'
		
		# Load the adapter.
		@_adapter = switch options?.store ? 'redis'
			
			when 'redis'
				
				redis = require 'connect-redis/node_modules/redis'

				require('socket.io-redis')(
					pubClient: redis.createClient()
					subClient: redis.createClient()
				)
				
	# ## ::channelsSocketIsIn
	# 
	# *Get a list of channels a socket is in.*
	# 
	# * (socket) `socket` - A socket.
	channelsSocketIsIn: (socket) -> socket.rooms
	
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
			
			# Join a '$global' channel.
			socket.join '$global', (error) =>
				return logger.error errors.stack error if error?
			
				# Run the disconnection middleware on disconnect.
				socket.on 'disconnect', =>
					@_disconnectionMiddleware.dispatch socket.request, null, (error) ->
						return logger.error errors.stack error if error?
				
				# Dispatch the connection middleware.
				@_connectionMiddleware.dispatch socket.request, null, (error) =>
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
