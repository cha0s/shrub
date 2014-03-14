
exports.$appConfig = [
	'$injector', '$routeProvider', '$locationProvider', 'pkgmanProvider'
	($injector, $routeProvider, $locationProvider, pkgmanProvider) ->
	
# Set up routes.
		routes = {}
		pkgmanProvider.invoke 'route', (path, route) -> routes[path] = route
		pkgmanProvider.invoke 'routeAlter', (_, fn) ->
			
			$injector.invoke(
				fn, null
				routes: routes
			)
		
		for path, route of routes
			
			do (path, route) ->
			
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
			
		$locationProvider.html5Mode true
]

exports.$appRun = [
	'$rootScope', '$location'
	($rootScope, $location) ->
		
		$rootScope.$watch(
			-> $location.path()
			-> $rootScope.urlClass = $location.path().substr(1).replace '/', '-'
		)
		
]

exports.$routeMock = path: 'e2e/sanity-check'
