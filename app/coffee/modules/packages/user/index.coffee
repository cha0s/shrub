
exports.$service = [
	'$q', 'rpc', 'schema'
	($q, rpc, schema) ->
		
		user = new schema.User
		
		isLoggedIn: (fn) -> @promise.then (user) -> fn user.id? 
			
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
		
		promise: rpc.call('user').then(
			(O) ->
				user.fromObject O
				user
		)
		
]

exports.$endpoint = 

	(req, fn) ->
		
		{models: User: User} = require 'server/jugglingdb'
	
		fn null, if req.user?
			req.user
		else
			new User()

exports[path] = require "packages/user/#{path}" for path in [
	'forgot', 'login', 'logout', 'register', 'reset'
]
