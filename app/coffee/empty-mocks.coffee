
# Stubs for the systems that are mocked out when running tests.

angular.module 'Shrub.mocks', [
	'Shrub.mocks.mockRouteProvider'
]

angular.module('Shrub.mocks.mockRouteProvider', []).provider 'mockRoute', [
	->
		
		when: ($routeProvider) ->
		$get: ->

]
