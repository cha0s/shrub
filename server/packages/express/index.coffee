
express = require 'express'
fs = require 'fs'
http = require 'http'
nconf = require 'nconf'
Promise = require 'bluebird'
winston = require 'winston'

class Express extends (require 'AbstractHttp')
	
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
	
	cookieParser: -> express.cookieParser @cookieSecret()
	
	cookieSecret: -> @_config.sessions.cookie.cryptoKey

	listen: (fn) ->
		
		errorCallback = (error) =>
			return fn error unless 'EADDRINUSE' is error.code
			
			winston.info "Address in use... retrying in 2 seconds"
			
			setTimeout (=> @_server.listen @port()), 2000
		
		@_server.on 'error', errorCallback
		
		@_server.once 'listening', =>
			@_server.removeListener 'error', errorCallback
			fn()
		
		@_server.listen @port()
	
	loadSessionFromRequest: (req) ->
		
		new Promise (resolve, reject) =>
		
			@cookieParser() req, {}, (error) =>
				return reject error if error?
				
				(req.sessionStore = @sessionStore()).load(
					req.signedCookies[@sessionKey()]
					(error, session) ->
						return reject error if error?
						return reject new Error 'No session!' unless session?
						
						session.req = session
						resolve session
				)
			
	renderAppHtml: (locals) ->
		
		new Promise (resolve, reject) =>
		
			@_app.render 'app', _locals: locals, (error, html) ->
				return reject error if error?
				
				resolve html
	
	server: -> @_server
	
	sessionId: (req) -> req.session.id

	sessionKey: -> @_config.sessions.key
	
	sessionStore: ->
		
		switch @_config.sessions.db
			when 'redis'
				
				module = require 'connect-redis/node_modules/redis'
		
				RedisStore = require('connect-redis') express
				new RedisStore client: module.createClient()

exports.$initialize = (config) ->
	
	new Promise (resolve, reject) ->
	
		http = new Express settings = nconf.get 'packageSettings:express'
		http.initialize (error) ->
			return reject error if error?
			
			console.info "Shrub Express HTTP server up and running on port #{
				settings.port
			}!"
			resolve()

exports.$settings = ->

	middleware: [
		'core'
		'socket/factory'
		'form'
		'express/session'
		'user'
		'express/logger'
		'express/routes'
		'express/static'
		'config'
		'assets'
		'angular'
		'express/errors'
	]

	path: "#{nconf.get 'path'}/app"
	
	port: 4201
	
	sessions:
		
		db: 'redis'
		
		key: 'connect.sid'
		
		cookie:
			
			cryptoKey: 'CookiesAreDelicious'
	
			maxAge: 1209600000
			
exports[path] = require "./#{path}" for path in [
	'errors', 'logger', 'routes', 'session', 'static'
]
