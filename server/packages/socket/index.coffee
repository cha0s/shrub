
# # Socket
# 
# Manage socket connections.

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
		'socket/factory'
		'session'
		'user'
		'rpc'
	]

	# Module implementing the socket.
	module: 'packages/socket/SocketIo'
	
	# Backing store for socket connections.
	# `TODO`: This probably doesn't belong here.
	store: 'redis'

exports[path] = require "./#{path}" for path in [
	'factory'
]
