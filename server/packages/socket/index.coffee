
# # Socket
# 
# Manage socket connections.

nconf = require 'nconf'

# The socket manager.
socketManager = null

# ## Implements hook `httpInitializing`
exports.$httpInitializing = (http) ->
	
	Manager = require nconf.get 'packageSettings:socket:manager:module'
	
	# Spin up the socket server, and have it listen on the HTTP server.
	socketManager = new Manager
	socketManager.loadMiddleware()
	socketManager.listen http
	
# ## Implements hook `packageSettings`
exports.$packageSettings = ->

	# Middleware stack dispatched to authorize or reject a socket connection.
	authorizationMiddleware: [
		'core'
		'session'
		'user'
		'villiany'
	]

	# Middleware stack dispatched once a socket connection is authorized.
	connectionMiddleware: [
		'session'
		'user'
		'rpc'
	]

	manager:
	
		# Module implementing the socket manager.
		module: 'packages/socket/SocketIoManager'

# ## Implements hook `replContext`
exports.$replContext = (context) ->
	
	# Provide the socketManager to REPL.
	context.socketManager = socketManager

# ## manager
exports.manager = -> socketManager
