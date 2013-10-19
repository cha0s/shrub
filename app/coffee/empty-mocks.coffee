
# Stubs for the systems that are mocked out when running tests.

angular.module 'shrub.mocks', [
	'shrub.mocks.mockRouteProvider'
]

angular.module('shrub.mocks.mockRouteProvider', []).provider 'mockRoute', [
	->
		
		when: ($routeProvider) ->
		$get: ->

]
