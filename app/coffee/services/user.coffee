$module.service 'user', [
	'$q', 'rpc', 'schema'
	($q, rpc, schema) ->
		
		user = new schema.User
		
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
