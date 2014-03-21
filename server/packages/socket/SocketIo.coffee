
crypto = require 'server/crypto'
Promise = require 'bluebird'

errors = require 'errors'
logging = require 'logging'
pkgman = require 'pkgman'

logger = new logging.create 'logs/socket.io.log'
	
AbstractSocketFactory = require 'AbstractSocketFactory'

module.exports = class SocketIo extends AbstractSocketFactory
	
	constructor: ->
		super
	
	socketsInChannel: (channel) -> @io.sockets.clients channel
		
	listen: (http) ->
	
		# Set up the socket.io server.
		@io = (require 'socket.io').listen(
			http.server()
			
			'log level': 'debug'
			logger: logger
			store: @store()
			transports: [
				'websocket'
				'flashsocket'
				'htmlfile'
				'xhr-polling'
				'jsonp-polling'
			]
		)
		
		# Suppress most logs in production
		@io.configure 'production', => @io.set 'log level', 'error'
		
		requestObjects = {}
		
		@io.set 'authorization', (handshake, fn) =>
			
			req = {}
			req[key] = value for key, value of handshake

			req.http = http
			
			@_authorizationMiddleware.dispatch req, null, (error) ->
				
				if error instanceof AbstractSocketFactory.AuthorizationFailure
					return fn null, false
					
				return fn error if error?
				
				crypto.randomBytes(24).then (key) ->
					
					handshake.requestKey = key.toString 'hex'
					
					# Remove the handshake values
					delete req[key] for key of handshake
					
					requestObjects[handshake.requestKey] = req
					
					fn null, true
				
		@io.sockets.on 'connection', (socket) =>
			
			for key, value of  requestObjects[socket.handshake.requestKey]
				socket.handshake[key] = value
			
			requestObjects[socket.handshake.requestKey] = null
			req = socket.handshake
			
			socket.join '$global'
			
			req.http = http
			req.socket = socket
			
			@_requestMiddleware.dispatch req, null, (error) ->
				return logger.error errors.stack error if error?
				
				socket.emit 'initialized'
			
	store: ->

		switch @_config.store
			
			when 'redis'
				
				redis = require 'connect-redis/node_modules/redis'
				RedisStore = require 'socket.io/lib/stores/redis'
				
				new RedisStore(
					redis: redis
					redisPub: redis.createClient()
					redisSub: redis.createClient()
					redisClient: redis.createClient()
				)
