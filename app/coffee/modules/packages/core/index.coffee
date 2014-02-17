
exports.$appConfig = [
	'$injector', '$routeProvider', '$locationProvider', 'pkgmanProvider'
	($injector, $routeProvider, $locationProvider, pkgmanProvider) ->
	
# Set up routes.
		pkgmanProvider.invoke 'route', (path, route) ->
			
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
			
			route.template ?= ' '
			
			$routeProvider.when "/#{route.path ? path}", route
		
# Create a unique entry point.
		$routeProvider.when '/shrub-entry-point', {}
			
		$routeProvider.otherwise redirectTo: '/home'
		
		$locationProvider.html5Mode true
]

exports[path] = require "packages/core/#{path}" for path in [
	'debug', 'form', 'schema', 'server'
]
