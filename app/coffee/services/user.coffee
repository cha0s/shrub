$module.service 'user', [
	'$q', 'rpc', 'schema'
	($q, rpc, schema) ->
		
		user = new schema.User
		
		forgot: (usernameOrEmail) ->
			
			rpc.call(
				'user.forgot'
				usernameOrEmail: usernameOrEmail
			)

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
		
		register: (username, email) ->

			rpc.call(
				'user.register'
				username: username
				email: email
			)
			
		reset: (token, password) ->

			rpc.call(
				'user.reset'
				token: token
				password: password
			)
			
		promise: rpc.call('user').then(
			(O) ->
				user.fromObject O
				user
		)
		
]
