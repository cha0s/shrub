
path = require 'path'
domain = require 'domain'

RedisStore = require path.join 'socket.io', 'lib', 'stores', 'redis'

module.exports = new class
	
	initialize: (app) ->
		
		redis = app.get 'redis'
		sessions = app.get 'sessions'

# Set up the socket.io server.
		io = require('socket.io').listen app.server
		
# Use redis so we won't always be tied to one process on one machine.
	
		io.set 'store', new RedisStore(
			redis: redis.module
			redisPub: redis.module.createClient()
			redisSub: redis.module.createClient()
			redisClient: redis.module.createClient()
		)

		io.set 'transports', [
			'websocket'
			'flashsocket'
			'htmlfile'
			'xhr-polling'
			'jsonp-polling'
		]
	
# Suppress most logs in production
		io.configure 'production', => io.set 'log level', 1
		
# Handle socket authorization, which will tie the socket to a session.
		io.set 'authorization', (data, accept) =>
		
			return accept(
				new Error 'No cookie; no session!'
				false
			) unless data and data.headers and data.headers.cookie
			
			sessions.cookieParser data, {}, (error) =>
				
				return accept error, false if error?
				
				sessionId = data.signedCookies[sessions.key]
				sessions.store.load sessionId, (error, session) ->
					
					return accept error, false if error?
					
					return accept(
						new Error 'No session!'
						false
					) unless session?
					
					data.session = session
					
					accept null, true
		
# Route socket traffic.

		routesDirectory = path.join __dirname, 'socketware'
		socketware = [
			'shrub'
			'sayHello'
		].map (name) -> require path.join routesDirectory, name
		
		io.sockets.on 'connection', (socket) =>
			
			reportError = (error) => io.log.error error.stack
			
			req =
				app: app
				io: io
				socket: socket
			
			d = domain.create()
			d.run => using req, reportError for using in socketware
			d.on 'error', reportError
