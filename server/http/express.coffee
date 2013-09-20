
express = require 'express'
fs = require 'fs'
http = require 'http'
nconf = require 'nconf'
path = require 'path'
Q = require 'q'
winston = require 'winston'

module.exports = class Express extends (require './http')
	
	constructor: (@_path) ->
		super
		
		@_app = express()
		
		# Handlebars!
		@_app.set 'views', @_path
		@_app.set 'view engine', 'html'
		@_app.engine 'html', require('hbs').__express
		
		@_server = http.createServer @_app
		
		@registerMiddleware()
	
	path: -> @_path
	
	cookieParser: -> express.cookieParser @_config.express.sessions.secret

	listen: (fn) ->
		
		@_server.listen @port(), fn
	
	loadSessionFromRequest: (req) ->
		deferred = Q.defer()
		
		@cookieParser() req, {}, (error) =>
			deferred.reject error if error?
			
			@sessionStore().load(
				req.signedCookies[@sessionKey()]
				(error, session) ->
					deferred.reject error if error?
					deferred.reject new Error 'No session!' unless session?
					
					deferred.resolve session
			)
			
		deferred.promise
			
	renderApp: (locals) ->
		deferred = Q.defer()
		
		@_app.render 'app', _locals: locals, (error, index) ->
			return deferred.reject error if error?
			
			deferred.resolve index
		
		deferred.promise
	
	server: -> @_server
	
	sessionId: (req) -> req.session.id

	sessionKey: -> @_config.express.sessions.key
	
	sessionStore: ->
		
		switch @_config.express.sessions.db
			when 'redis'
				
				module = require path.join 'connect-redis', 'node_modules', 'redis'
		
				RedisStore = require('connect-redis') express
				new RedisStore client: module.createClient()
	
	use: (fn) -> @_app.use fn
