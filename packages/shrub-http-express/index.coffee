
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
	
	# ### ::listener
	# 
	# *Listen for HTTP connections.*
	listener: ->
		
		new Promise (resolve, reject) =>
		
			@_server.on 'error', reject
			
			@_server.once 'listening', =>
				@_server.removeListener 'error', reject
				resolve()
			
			# } Bind to the listen port.
			@_server.listen @port()
	
	# ### ::renderAppHtml
	# 
	# * (object) `locals` - The locals to pass to the templating engine.
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
