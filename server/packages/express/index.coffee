
# # Express
# 
# An [Express](http://expressjs.com/) HTTP server implementation, with
# middleware for sessions, routing, logging, etc.

express = require 'express'
fs = require 'fs'
http = require 'http'
nconf = require 'nconf'
Promise = require 'bluebird'

{defaultLogger} = require 'logging'

# ## Express
# 
# An implementation of [AbstractHttp](../../AbstractHttp.html) using the
# Express framework.
class Express extends (require 'AbstractHttp')
	
	# ### *constructor*
	# 
	# *Create the server.*
	constructor: ->
		super
		
		# } Create the Express instance.
		@_app = express()
		
		# } Register middleware.
		@registerMiddleware()
		
		# } Handlebars!
		# } `TODO`: Do we really need to use Express's theme system..?
		@_app.set 'views', @_config.path
		@_app.set 'view engine', 'html'
		@_app.engine 'html', require('hbs').__express
		
		# } Spin up an HTTP server.
		@_server = http.createServer @_app
		
		# } Connect (no pun) Express's middleware system to ours.
		@_app.use (req, res, next) => @_middleware.dispatch req, res, next
	
	# ### ::path
	# 
	# *The path where statuc files are served from.*
	path: -> @_config.path
	
	# ### ::cookieParser
	# 
	# *Express cookie parser middleware.*
	cookieParser: -> express.cookieParser @cookieSecret()
	
	# ### ::cookieSecret
	# 
	# *The crypto key used to encrypt cookies.*
	cookieSecret: -> @_config.sessions.cookie.cryptoKey

	# ### ::listen
	# 
	# *Listen for HTTP connections.*
	# 
	# * (function) `fn` - The function to call when the server is listening.
	listen: ->
		
		new Promise (resolve, reject) =>
		
			# } Catch errors. If it's an address in use error then complain
			# } about it, but try again.
			errorCallback = (error) =>
				return reject error unless 'EADDRINUSE' is error.code
				
				defaultLogger.error "Address in use... retrying in 2 seconds"
				
				setTimeout (=> @_server.listen @port()), 2000
			@_server.on 'error', errorCallback
			
			@_server.once 'listening', =>
				@_server.removeListener 'error', errorCallback
				resolve()
			
			# } Bind to the listen port.
			@_server.listen @port()
	
	# ### ::loadSessionFromRequest
	# 
	# * (object) `req` - The request object.
	# 
	# *Parse the request's cookies and load any session.*
	loadSessionFromRequest: (req) ->
		
		new Promise (resolve, reject) =>
			
			# } Make sure there's a possibility we will find a session.
			unless req and req.headers and req.headers.cookie
				return resolve()
		
			@cookieParser() req, null, (error) =>
				return reject error if error?
				
				# } Tricky: Assign req.sessionStore, because Express session
				# } functionality will be broken unless it exists.
				(req.sessionStore = @sessionStore()).load(
					req.signedCookies[@sessionKey()]
					(error, session) ->
						return reject error if error?
						return resolve() unless session?
						
						session.req = session
						resolve session
				)
			
	# ### ::renderAppHtml
	# 
	# * (object) `locals` - The locals to pass to handlebars.
	# 
	# *Render the application HTML.*
	renderAppHtml: (locals) ->
		
		new Promise (resolve, reject) =>
		
			@_app.render 'app', _locals: locals, (error, html) ->
				return reject error if error?
				
				resolve html
	
	# ### ::server
	# 
	# *The node HTTP server instance.*
	server: -> @_server
	
	# ### ::sessionKey
	# 
	# *The cookie key where the session ID will be found.*
	sessionKey: -> @_config.sessions.key
	
	# ### ::sessionStore
	# 
	# *The session store.*
	# 
	# `TODO`: Cache this!
	sessionStore: ->
		
		switch @_config.sessions.db
			when 'redis'
				
				module = require 'connect-redis/node_modules/redis'
		
				RedisStore = require('connect-redis') express
				new RedisStore client: module.createClient()

# ## Implements hook `initialize`
exports.$initialize = (config) ->
	
	http = new Express settings = nconf.get 'packageSettings:express'
	http.initialize().then ->
	
		defaultLogger.info "Shrub Express HTTP server up and running on port #{
			settings.port
		}!"
	
# ## Implements hook `packageSettings`
exports.$packageSettings = ->

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
