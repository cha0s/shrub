
# # Schema
# 
# Provide the JugglingDB schema as an Angular service.

config = require 'config'

# ## Implements hook `service`
exports.$service = -> [
	'$http', 'require'
	($http, require) ->

		require('schema-client').define(
			require 'jugglingdb-rest'
			$http: $http
			apiRoot: config.get 'apiRoot'
		)
		
]