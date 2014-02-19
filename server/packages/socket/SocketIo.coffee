
winston = require 'winston'

logger = new winston.Logger
	transports: [
		new winston.transports.Console level: 'error', colorize: true
		new winston.transports.File level: 'debug', filename: 'logs/socket.io.log'
	]

module.exports = class SocketIo extends (require 'AbstractSocket')
	
	constructor: (http) ->
		super
		
		# Set up the socket.io server.
		@io = require('socket.io').listen(
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
				
				req.socket.emit 'initialized'
			
	store: ->

		# Should this be dynamic?
		switch @_config.socketIo.db
			
			when 'redis'
				
				module = require 'connect-redis/node_modules/redis'
				
				new (require 'socket.io/lib/stores/redis')(
					redis: module
					redisPub: module.createClient()
					redisSub: module.createClient()
					redisClient: module.createClient()
				)
