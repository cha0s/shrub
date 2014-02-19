
exports.$models = (schema) ->
	
	User = schema.define 'User',
		
		email:
			type: String
			index: true
		
		name:
			type: String
			default: 'Anonymous'
			length: 24
			index: true
			
		passwordHash:
			type: String
		
		resetPasswordToken:
			type: String
			length: 128
			index: true
		
		salt:
			type: String
			length: 128
			
	# Temporary... secure by default.
	User::hasPermission = (perm) -> false
	User::isAccessibleBy = -> false
	
	User::redactFor = (user) ->
		
		@passwordHash = null
		@resetPasswordToken = null
		@salt = null
		
		this
	
exports.$service = [
	'$q', 'rpc', 'schema'
	($q, rpc, schema) ->
		
		user = new schema.User
		
		isLoggedIn: (fn) -> @load().then (user) -> fn user.id? 
			
		login: (method, username, password) ->
			
			rpc.call(
				'user.login'
				method: method
				username: username
				password: password
			).then(
				(O) ->
					user.fromObject O
					user
			)

		logout: ->
			
			rpc.call(
				'user.logout'
			).then(
				->
					user.fromObject (new schema.User).toObject()
					user
			)
		
		load: -> rpc.call('user').then (O) ->
			user.fromObject O
			user
		
]

exports.$serviceMock = [
	'$delegate', 'socket'
	($delegate, socket) ->
	
		socket.catchEmit 'rpc://user', (data, fn) ->
			fn result: name: 'Anonymous'
		
		$delegate
		
]

exports[path] = require "packages/user/#{path}" for path in [
	'forgot', 'login', 'logout', 'register', 'reset'
]
