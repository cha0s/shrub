
# # Socket.IO
# 
# SocketManager implementation using [Socket.IO](http://socket.io/).

crypto = require 'server/crypto'
nconf = require 'nconf'
Promise = require 'bluebird'

errors = require 'errors'
logging = require 'logging'
pkgman = require 'pkgman'

logger = new logging.create 'logs/socket.io.log'
	
SocketManager = require './manager'
{AuthorizationFailure} = SocketManager

# ## SocketIoManager
# Implements `SocketManager`.
# 
# A socket factory implemented with [Socket.IO](http://socket.io/).
module.exports = class SocketIoManager extends SocketManager
	
	# ## *constructor*
	constructor: ->
		super
		
		options = nconf.get 'packageSettings:socket:manager:options'
		
		# Load the backing store.
		@_store = switch options?.store ? 'redis'
			
			when 'redis'
				
				redis = require 'connect-redis/node_modules/redis'
				RedisStore = require 'socket.io/lib/stores/redis'
				
				new RedisStore(
					redis: redis
					redisPub: redis.createClient()
					redisSub: redis.createClient()
					redisClient: redis.createClient()
				)
	
	# ## ::channelsSocketIsIn
	# 
	# *Get a list of channels a socket is in.*
	# 
	# * (socket) `socket` - A socket.
	channelsSocketIsIn: (socket) ->
	
		@io.sockets.manager.roomClients[socket.id]
	
	# ## ::listen
	# Implements `SocketManager::listen`.
	listen: (http) ->
	
		# Set up the socket.io server.
		@io = (require 'socket.io').listen(
			http.server()
			
			# Suppress most logs in production
			'log level': if 'production' is process.env.NODE_ENV
				'error'
			else
				'debug'
			logger: logger
			store: @_store
			transports: [
				'websocket'
				'flashsocket'
				'htmlfile'
				'xhr-polling'
				'jsonp-polling'
			]
		)
		
		# We can't leave everything we put into req from the authorization
		# middleware in the socket handshake, since the handshake will be
		# stringified. Instead, we'll store a 24-byte key into this object in
		# the handshake, and when the connection is authorized, we'll use that
		# key from the connection middleware to restore everything to req.
		requestObjects = {}
		
		# Authorization.
		@io.set 'authorization', (handshake, fn) =>
			
			# Derive a request object from the handshake.
			{IncomingMessage} = require 'http'
			req = new IncomingMessage null
			
			req[key] = value for key, value of handshake
			req.http = http
			
			# Dispatch the authorization middleware.
			@_authorizationMiddleware.dispatch req, null, (error) ->
				
				# If `AuthorizationFailure` was thrown, the connection is
				# rejected as unauthorized.
				if error instanceof AuthorizationFailure
					return fn null, false
					
				# If any other kind of error was thrown, propagate it.
				return fn error if error?
				
				# Generate a random key to store the request object.
				crypto.randomBytes(24).then (requestKey) ->
					
					# Remove the handshake values.
					delete req[key] for key of handshake
					
					# Store the request object and accept authentication.
					handshake.requestKey = requestKey.toString 'hex'
					requestObjects[handshake.requestKey] = req
					fn null, true
				
		# Connection (post-authorization).
		@io.sockets.on 'connection', (socket) =>
			
			# Use the handshake as the request base, and augment it with the
			# request object from the authentication phase, plus some other
			# goodies.
			req = requestObjects[socket.handshake.requestKey]
			req[key] = value for key, value of socket.handshake
			
			# Socket.IO hax. socket.handshake is behind a getter, so we'll get
			# in the internals.
			socket.manager.handshaken[socket.id] = req
			
			req.http = http
			req.socket = socket
			
			# Release the request object reference.
			requestObjects[req.requestKey] = null
			delete req.requestKey
			
			# Join a '$global' channel.
			socket.join '$global'
			
			# Dispatch the connection middleware.
			@_connectionMiddleware.dispatch req, null, (error) ->
				return logger.error errors.stack error if error?
				
				socket.emit 'initialized'
			
	# ## ::socketsInChannel
	# 
	# *Get a list of sockets in a channel.*
	# 
	# * (string) `channelName` - The channel or 'room' name.
	socketsInChannel: (channelName) -> @io.sockets.clients channelName
