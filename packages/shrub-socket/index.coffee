
# # Socket
#
# Manage socket connections.

config = require 'config'

# The socket manager.
socketManager = null

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `config`
	registrar.registerHook 'config', ->

		socketModule = if (config.get 'E2E')?

			'shrub-socket/dummy'

		else

			config.get 'packageSettings:shrub-socket:manager:module'

		manager: module: socketModule

	# ## Implements hook `httpInitializing`
	registrar.registerHook 'httpInitializing', (http) ->

		{Manager} = require config.get 'packageSettings:shrub-socket:manager:module'

		# Spin up the socket server, and have it listen on the HTTP server.
		socketManager = new Manager()
		socketManager.loadMiddleware()
		socketManager.listen http

	# ## Implements hook `packageSettings`
	registrar.registerHook 'packageSettings', ->

		# Middleware stack dispatched to authorize or reject a socket connection.
		authorizationMiddleware: [
			'shrub-core'
			'shrub-http-express/session'
			'shrub-user'
			'shrub-villiany'
		]

		# Middleware stack dispatched once a socket connection is authorized.
		connectionMiddleware: [
			'shrub-session'
			'shrub-user'
			'shrub-rpc'
		]

		# Middleware stack dispatched when socket disconnects.
		disconnectionMiddleware: []

		manager:

			# Module implementing the socket manager.
			module: 'shrub-socket-socket.io'

	# ## Implements hook `replContext`
	registrar.registerHook 'replContext', (context) ->

		# Provide the socketManager to REPL.
		context.socketManager = socketManager

# ## manager
exports.manager = -> socketManager
