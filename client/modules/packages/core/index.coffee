
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
			
		$locationProvider.html5Mode true
]

exports.$routeMock = path: 'e2e/sanity-check'

exports.$service = [
	'$q'
	($q) ->
		
		service = {}
		
		service.promiseify = (holder, method) -> ->
			
			deferred = $q.defer()
			
			method.apply(
				holder
				(arg for arg in arguments).concat [
					(error, result) ->
						return deferred.reject error if error?
						deferred.resolve result
				]
			)
			
			deferred.promise
			
		service
		
]