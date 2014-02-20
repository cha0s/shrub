
express = require 'express'
fs = require 'fs'
http = require 'http'
path = require 'path'
Q = require 'q'
winston = require 'winston'

exports.$http = class Express extends (require 'AbstractHttp')
	
	constructor: ->
		super
		
		@_app = express()
		
		# Handlebars!
		@_app.set 'views', @_config.path
		@_app.set 'view engine', 'html'
		@_app.engine 'html', require('hbs').__express
		
		@_server = http.createServer @_app
		
		@registerMiddleware()
		
		@_app.use (req, res, next) => @_middleware.dispatch req, res, next
	
	path: -> @_config.path
	
	cookieParser: -> express.cookieParser @_config.express.sessions.cookie.cryptoKey

	listen: (fn) -> @_server.listen @port(), fn
	
	loadSessionFromRequest: (req) ->
		deferred = Q.defer()
		
		@cookieParser() req, {}, (error) =>
			deferred.reject error if error?
			
			(req.sessionStore = @sessionStore()).load(
				req.signedCookies[@sessionKey()]
				(error, session) ->
					return deferred.reject error if error?
					return deferred.reject new Error 'No session!' unless session?
					
					session.req = session
					deferred.resolve session
			)
			
		deferred.promise
			
	renderApp: (locals, fn) ->
		
		@_app.render 'app', _locals: locals, (error, index) ->
			return fn error if error?
			
			fn null, index
	
	server: -> @_server
	
	sessionId: (req) -> req.session.id

	sessionKey: -> @_config.express.sessions.key
	
	sessionStore: ->
		
		switch @_config.express.sessions.db
			when 'redis'
				
				module = require path.join 'connect-redis', 'node_modules', 'redis'
		
				RedisStore = require('connect-redis') express
				new RedisStore client: module.createClient()
