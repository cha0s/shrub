
# # Express
# 
# An [Express](http://expressjs.com/) HTTP server implementation, with
# middleware for sessions, routing, logging, etc.

express = require 'express'
fs = require 'fs'
http = require 'http'
Promise = require 'bluebird'

{handlebars} = require 'hbs'
readFile = Promise.promisify fs.readFile, fs

{defaultLogger} = require 'logging'

exports.pkgmanRegister = (registrar) ->
	
	registrar.recur [
		'errors', 'logger', 'routes', 'session', 'static'
	]
	
# An implementation of [HttpManager](../http/manager.html) using the
# Express framework.
exports.Manager = class Express extends (require '../shrub-http/manager')

	# ### *constructor*
	# 
	# *Create the server.*
	constructor: ->
		super
		
		# } Create the Express instance.
		@_app = express()
		
		# } Register middleware.
		@registerMiddleware()
		
		# } Spin up an HTTP server.
		@_server = http.createServer @_app
		
		# } Connect (no pun) Express's middleware system to ours.
		@_app.use (req, res, next) => @_middleware.dispatch req, res, next
	
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
	
	# ### ::renderAppHtml
	# 
	# * (object) `locals` - The locals to pass to handlebars.
	# 
	# *Render the application HTML.*
	renderAppHtml: (locals) ->
		
		readFile(
			"#{@_config.path}/app.html", encoding: 'utf8'
		
		).then (html) -> handlebars.compile(html) locals
			
	# ### ::server
	# 
	# *The node HTTP server instance.*
	server: -> @_server
