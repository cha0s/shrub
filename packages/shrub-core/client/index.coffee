
# # Core
# 
# Core functionality.

Promise = require 'bluebird'

config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `appConfig`
	registrar.registerHook 'appConfig', -> [
		'$injector', '$provide', '$routeProvider', '$locationProvider', 'shrub-pkgmanProvider'
		($injector, $provide, $routeProvider, $locationProvider, pkgmanProvider) ->
		
			# Completely override $q with Bluebird, because it's awesome.
			$provide.decorator '$q', [
				'$rootScope', '$exceptionHandler'
				($rootScope, $exceptionHandler) ->
				
					Promise.onPossiblyUnhandledRejection $exceptionHandler
					Promise.setScheduler (fn) -> $rootScope.$evalAsync fn
				
					Promise.defer = ->
						resolve = null
						reject = null
						
						promise = new Promise ->
							resolve = arguments[0]
							reject = arguments[1]
							
						promise: promise
						resolve: resolve
						reject: reject
						
					Promise.when = (value, handlers...) ->
						Promise.cast(value).then handlers...
					
					originalAll = Promise.all
					Promise.all = (promises) ->
						
						return originalAll promises unless angular.isObject(
							promises
						)
						
						promiseArray = []
						promiseKeysArray = []

						angular.forEach promises, (promise, key) ->
							promiseKeysArray.push key
							promiseArray.push promise
		
						originalAll(promiseArray).then (results) ->
							objectResult = {}
							
							angular.forEach results, (result, index) ->
								objectResult[promiseKeysArray[index]] = result
		
							objectResult
					
					Promise
					
			]
			
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
			if config.get 'packageConfig:shrub-core:testMode'
				for path, route of pkgmanProvider.invoke 'routeMock'
					routes[route.path ? path] = route
				
			# Invoke hook `routeAlter`.
			# Allow packages to alter defined routes.
			$injector.invoke(
				injectable, null
				routes: routes
			) for injectable in pkgmanProvider.invokeFlat 'routeAlter'
			
			for path, route of routes
				do (path, route) ->
					
					# Wrap the controller so we can provide some automatic
					# behavior.
					routeController = route.controller
					route.controller = [
						'$controller', '$injector', '$scope'
						($controller, $injector, $scope) ->
							
							# Invoke hook `routeControllerStart`.
							# Allow packages to act before a new route controller
							# is executed.
							injectables = pkgmanProvider.invokeFlat(
								'routeControllerStart'
							)
							
							injectables.push routeController
							
							$injector.invoke(
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
			$locationProvider.html5Mode true
	]
	
	# ## Implements hook `appRun`
	registrar.registerHook 'appRun', -> [
		'$rootScope', '$location', '$window', 'shrub-socket'
		($rootScope, $location, $window, socket) ->
			
			# Split the path into the corresponding classes, e.g.
			#
			# foo/bar/baz -> class="foo foo-bar foo-bar-baz"
			$rootScope.$watch (-> $location.path()), ->
				
				parts = $location.path().substr(1).split '/'
				parts = parts.map (part) -> part.replace /[^_a-zA-Z0-9-]/g, '-'
				
				classes = for i in [1..parts.length]
					parts.slice(0, i).join '-'
					
				$rootScope.pathClass = classes.join ' '
			
			# Navigate the client to `href`.
			socket.on 'core.navigateTo', (href) -> $window.location.href = href
			
			# Reload the client.
			socket.on 'core.reload', -> $window.location.reload()
			
			# Set up application close behavior.
			$window.addEventListener 'beforeunload', ->
				appCloseEvent = $rootScope.$emit 'shrub.core.appClose'
				true if appCloseEvent.defaultPrevented
			
	]
	
	# ## Implements hook `routeMock`
	# 
	# A simple path definition to make sure we're running in e2e testing mode.
	registrar.registerHook 'e2e', 'routeMock', -> path: 'e2e/sanity-check'
