
exports.$service = -> [
	'$http', 'config', 'require'
	($http, config, require) ->

		require('schema-client').define(
			require 'jugglingdb-rest'
			$http: $http
			apiRoot: config.get 'apiRoot'
		)
		
]
