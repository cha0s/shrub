
exports.$settings = ->

	middleware: [
		'core'
		'socket/factory'
		'session'
		'user'
		'rpc'
	]

	module: 'packages/socket/SocketIo'
	
	store: 'redis'

exports[path] = require "./#{path}" for path in [
	'factory'
]
