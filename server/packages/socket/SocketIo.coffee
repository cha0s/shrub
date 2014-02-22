
winston = require 'winston'

logger = new winston.Logger
	transports: [
		new winston.transports.Console level: 'error', colorize: true
		new winston.transports.File level: 'debug', filename: 'logs/socket.io.log'
	]

module.exports = class SocketIo extends (require 'AbstractSocketFactory')
	
	constructor: ->
		super
		
	emitToChannel: (channel, type, data, fn) =>
	
		@io.sockets.in(channel).emit type, data, (data) ->
			return unless fn?
			
			fn data
			
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
		
		@io.sockets.on 'connection', (socket) =>
			req = socket.handshake
			
			req.http = http
			req.socket = socket
			
			@_middleware.dispatch req, null, (error) ->
				return logger.error error if error?
				
				socket.emit 'initialized'
			
	store: ->

		switch @_config.options.store
			
			when 'redis'
				
				redis = require 'connect-redis/node_modules/redis'
				RedisStore = require 'socket.io/lib/stores/redis'
				
				new RedisStore(
					redis: redis
					redisPub: redis.createClient()
					redisSub: redis.createClient()
					redisClient: redis.createClient()
				)
