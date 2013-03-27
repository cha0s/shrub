
path = require 'path'
domain = require 'domain'

RedisStore = require path.join 'socket.io', 'lib', 'stores', 'redis'

module.exports = class
	
	constructor: ->
		
		@_middleware = []
	
	configure: (io, redis) ->
	
# User redis so we won't always be tied to one process on one machine.
	
		io.set 'store', new RedisStore(
			redis: redis
			redisPub: redis.createClient()
			redisSub: redis.createClient()
			redisClient: redis.createClient()
		)

# Make the transport mechanisms very liberal in production, but very limited
# in development.

		io.configure 'production', =>
			
			io.set 'log level', 1
			
			io.set 'transports', [
				'websocket'
				'flashsocket'
				'htmlfile'
				'xhr-polling'
				'jsonp-polling'
			]
		
		io.configure 'development', =>
		
			io.set 'transports', [
				'websocket'
			]
	
# Require a cookie and session for each socket.
	
	authorize: (io, sessionOptions) ->
	
		io.set 'authorization', (data, accept) =>
		
			return accept(
				new Error 'No cookie; no session!'
				false
			) unless data and data.headers and data.headers.cookie
			
			sessionOptions.cookieParser data, {}, (error) =>
				
				return accept error, false if error?
				
				sessionId = data.signedCookies[sessionOptions.key]
				sessionOptions.store.load sessionId, (error, session) ->
					
					return accept error, false if error?
					
					return accept(
						new Error 'No session!'
						false
					) unless session?
					
					data.session = session
					
					accept null, true
		
	route: (io, sessionOptions) ->
		
		io.sockets.on 'connection', (socket) =>
			
			reportError = (error) => io.log.error error.stack
			
			d = domain.create()
			
			d.run =>
				
				session = socket.handshake.session
				
				# Join the session room.
				socket.join session.id
				
				@_middleware.forEach (using) =>
					
					req =
						io: io
						socket: socket
						injectSession: (callback) ->
							args = (arguments[i] for i in [1...arguments.length])
							sessionOptions.store.load session.id, d.intercept (session) ->
								session.touch()
								session.save d.intercept ->
									args[args.length] = session
									callback.apply callback, args
								
					using req, reportError
				
			d.on 'error', reportError
			
	use: (middleware) -> (@_middleware ?= []).push middleware
