
# # Express
#
# An [Express](http://expressjs.com/) HTTP server implementation, with
# middleware for sessions, routing, logging, etc.

http = null

express = null

Promise = null

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `preBootstrap`
	registrar.registerHook 'preBootstrap', ->

		http = require 'http'

		express = require 'express'

		Promise = require 'bluebird'

	registrar.recur [
		'errors', 'logger', 'routes', 'session', 'static'
	]

# An implementation of [HttpManager](../http/manager.html) using the
# Express framework.
{Manager: HttpManager} = require '../shrub-http/manager'
exports.Manager = class Express extends HttpManager

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

	# ### ::addRoute
	#
	# *Add HTTP routes.*
	addRoute: ({verb, path, receiver}) -> @_app[verb] path, receiver

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

	# ### ::server
	#
	# *The node HTTP server instance.*
	server: -> @_server
