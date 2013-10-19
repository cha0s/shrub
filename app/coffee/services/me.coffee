$module.service 'me', [
	'$q', 'rpc', 'schema'
	($q, rpc, schema) ->
		
		deferred = $q.defer()
		
		rpc.call('me').then(
			(user) -> deferred.resolve new schema.User user
			(error) -> deferred.reject error
		)

		deferred.promise
		
]
