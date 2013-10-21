$module.service 'user', [
	'$q', 'rpc', 'schema'
	($q, rpc, schema) ->
		
		deferred = $q.defer()
		
		rpc.call('user').then(
			(user) -> deferred.resolve new schema.User user
			(error) -> deferred.reject error
		)
		
		deferred.promise
		
]
