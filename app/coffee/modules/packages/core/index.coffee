
exports.$appConfig = [
	'$injector', '$routeProvider', '$locationProvider', 'mockRouteProvider', 'requireProvider'
	($injector, $routeProvider, $locationProvider, mockRouteProvider, requireProvider) ->
	
# Set up package routes.
		pkgman = requireProvider.require 'pkgman'
		pkgman.invoke 'route', (path, route) ->

			routeController = route.controller
			route.controller = [
				'$injector', '$scope', 'ui/title'
				($injector, $scope, title) ->
					
					title.setPage route.title ? ''
					
					$injector.invoke(
						routeController, null
						$scope: $scope
					)
				
			]
			
			$routeProvider.when "/#{route.path ? path}", route
		
# Create a unique entry point.
		$routeProvider.when '/shrub-entry-point', {}
			
# Mock routes for testing, in development or production mode, this will be
# empty.
		mockRouteProvider.when $routeProvider
		
		$routeProvider.otherwise redirectTo: '/home'
		
		$locationProvider.html5Mode true
]

exports[path] = require "packages/core/#{path}" for path in [
	'config', 'debug', 'form', 'schema', 'server'
]
