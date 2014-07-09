
# # Core
# 
# Core functionality.

config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `appConfig`
	registrar.registerHook 'appConfig', -> [
		'$injector', '$routeProvider', '$locationProvider', 'shrub-pkgmanProvider'
		({invoke}, $routeProvider, {html5Mode}, pkgmanProvider) ->
			
			routes = {}
			
			# A route is defined like:
			# 
			# * `controller`: An [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation)
			#   which will be injected.
			# 
			# * `template`: A template string.
			# 
			# * `title`: A string which will be set as the page title.
	
			# Invoke hook `route`.
			# Allow packages to define routes in the Angular application.
			for path, route of pkgmanProvider.invoke 'route'
				routes[route.path ? path] = route
				
			# Invoke hook `routeMock`.
			# Allow packages to define routes in the Angular application which are
			# only defined during test mode.
			if config.get 'testMode'
				for path, route of pkgmanProvider.invoke 'routeMock'
					routes[route.path ? path] = route
				
			# Invoke hook `routeAlter`.
			# Allow packages to alter defined routes.
			invoke(
				injectable, null
				routes: routes
			) for injectable in pkgmanProvider.invokeFlat 'routeAlter'
			
			for path, route of routes
				do (path, route) ->
					
					# Wrap the controller so we can provide some automatic
					# behavior.
					routeController = route.controller
					route.controller = [
						'$injector', '$scope'
						({invoke}, $scope) ->
							
							# Invoke hook `routeControllerStart`.
							# Allow packages to act before a new route controller
							# is executed.
							injectables = pkgmanProvider.invokeFlat(
								'routeControllerStart'
							)
							
							injectables.push routeController
							
							invoke(
								injectable, null
								$scope: $scope
								route: route
							) for injectable in injectables
					]
					
					# `TODO`: Some method of allowing `templateUrl`.
					route.template ?= ' '
					
					# Register the path into Angular.
					$routeProvider.when "/#{route.path ? path}", route
			
			# Create a unique entry point.
			$routeProvider.when '/shrub-entry-point', {}
			
			# Turn on HTML5 mode: "Real" URLs.
			html5Mode true
	]
	
	# ## Implements hook `appRun`
	registrar.registerHook 'appRun', -> [
		'$rootScope', '$location', '$window', 'shrub-socket', 'shrub-ui/title'
		($rootScope, $location, $window, socket, {setSite}) ->
			
			$rootScope.$watch(
				-> $location.path()
				->
				
					# Split the path into the corresponding classes, e.g.
					#
					# foo/bar/baz -> class="foo foo-bar foo-bar-baz"
					parts = $location.path().substr(1).split '/'
					parts = for i in [1..parts.length]
						part = parts.slice(0, i).join '-'
						part.replace /[^_a-zA-Z0-9-]/g, '-'
						
					$rootScope.pathClass = parts.join ' '
			)
			
			# Navigate the client to `href`.
			socket.on 'core.navigateTo', (href) -> $window.location.href = href
			
			# Reload the client.
			socket.on 'core.reload', -> $window.location.reload()
			
			setSite config.get 'siteName'
			
	]
	
	# ## Implements hook `routeMock`
	# 
	# A simple path definition to make sure we're running in e2e testing mode.
	registrar.registerHook 'e2e', 'routeMock', -> path: 'e2e/sanity-check'
