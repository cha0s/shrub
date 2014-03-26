
# # Schema
# 
# Provide the JugglingDB schema as an Angular service.

# ## Implements hook `service`
exports.$service = -> [
	'$http', 'config', 'require'
	($http, config, require) ->

		require('schema-client').define(
			require 'jugglingdb-rest'
			$http: $http
			apiRoot: config.get 'apiRoot'
		)
		
]
