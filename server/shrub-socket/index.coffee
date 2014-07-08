
# # Socket
# 
# Manage socket connections.

config = require 'config'

# The socket manager.
socketManager = null

# ## Implements hook `httpInitializing`
exports.$httpInitializing = (http) ->
	
	{Manager} = require config.get 'packageSettings:shrub-socket:manager:module'
	
	# Spin up the socket server, and have it listen on the HTTP server.
	socketManager = new Manager
	socketManager.loadMiddleware()
	socketManager.listen http
	
# ## Implements hook `packageSettings`
exports.$packageSettings = ->

	# Middleware stack dispatched to authorize or reject a socket connection.
	authorizationMiddleware: [
		'shrub-core'
		'shrub-session/express'
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
		module: 'shrub-socket.io'

# ## Implements hook `replContext`
exports.$replContext = (context) ->
	
	# Provide the socketManager to REPL.
	context.socketManager = socketManager

# ## manager
exports.manager = -> socketManager
