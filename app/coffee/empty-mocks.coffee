
# Stubs for the systems that are mocked out when running tests.

angular.module 'AngularShrub.mocks', [
	'AngularShrub.mocks.mockRouteProvider'
]

angular.module('AngularShrub.mocks.mockRouteProvider', []).provider 'mockRoute', [
	->
		
		test: ($routeProvider) ->
		$get: ->

]
