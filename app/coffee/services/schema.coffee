
$module.service 'schema', [
	'$http', '$rootScope', '$q', 'require', 'socket'
	($http, $rootScope, $q, require, socket) ->

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
		
		{models} = require('schema').define(
			require('jugglingdb').Schema
			require 'jugglingdb-rest'
			$http: $http
		)
		
		for name, Model of models
			
			@[name] = Model
				
			Model[method] = promiseify Model, Model[method] for method in [
				'all', 'count', 'create', 'destroyAll', 'exists', 'find'
				'findOne', 'findOrCreate'
			]				
						
			Model.access = promiseify Model, Model.access
						
		return
		
]
