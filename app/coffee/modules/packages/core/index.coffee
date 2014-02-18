
exports.$config = (req) ->
	
	testMode: if (req.nconf.get 'E2E')? then 'e2e' else false
	debugging: 'production' isnt req.nconf.get 'NODE_ENV'
	packageList: req.nconf.get 'packageList'

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

exports[path] = require "packages/core/#{path}" for path in [
	'debug', 'form', 'schema', 'server'
]
