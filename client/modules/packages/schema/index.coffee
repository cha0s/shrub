
exports.$service = [
	'$http', 'config', 'require'
	($http, config, require) ->

		{models} = require('schema-client').define(
			require 'jugglingdb-rest'
			$http: $http
			apiRoot: config.get 'apiRoot'
		)
		
		models
		
]

exports.db = $service: [
	'$q', 'schema', 'user'
	($q, schema, user) ->

		promiseify = (holder, method) -> ->
			
			deferred = $q.defer()
			
			method.apply(
				holder
				(arg for arg in arguments).concat [
					(error, result) ->
						deferred.reject error if error?
						deferred.resolve result
				]
			)
			
			deferred.promise
		
		for name, Model of schema
			do (Model) =>
				access = Model.access
				Model.access = promiseify Model, (perm, args...) ->
					user.promise.then (user) ->
						access.apply Model, [perm, user].concat args
		
		schema
		
]
