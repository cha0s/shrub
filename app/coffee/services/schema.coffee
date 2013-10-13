
$module.service 'schema', [
	'$rootScope', '$q', 'require', 'socket'
	($rootScope, $q, require, socket) ->

		{models} = require('schema').define(
			require('jugglingdb').Schema
			require 'jugglingdb-socket'
			socket: socket
		)
		
		for name, Model of models
			
			@[name] = Model
				
			# Override methods to promise-ify then.
			do (Model) =>
				for method in [
					'all', 'count', 'create', 'destroyAll', 'exists', 'find'
					'findOne', 'findOrCreate'
				]				
					do (method) =>
						originalMethod = Model[method]
						Model[method] = =>
										
							deferred = $q.defer()
							
							originalMethod.apply(
								Model
								(arg for arg in arguments).concat [
									(error, result) ->
										deferred.reject error if error?
										deferred.resolve result
								]
							)
							
							deferred.promise
						
		return
		
]
