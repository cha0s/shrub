
# # Core
# 
# Core functionality.

# ## Implements hook `appConfig`
exports.$appConfig = -> [
	'$injector', '$routeProvider', '$locationProvider', 'pkgmanProvider'
	({invoke}, $routeProvider, {html5Mode}, {invokeWithMocks}) ->
	
		# Invoke hook `route`.
		# Allow packages to define routes in the Angular application.
		# 
		# `TODO`: Should just be .invoke, routeMock done separately.
		routes = invokeWithMocks 'route'

		# Implementations should return an object of the form:
		{
		
			# An [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation)
			# which will be injected.
			controller: '...'
			 
			# A template string.
			template: '...'
			 
			# A string which will be set as the page title.
			title: '...'
			
		}
			
		# Invoke hook `routeAlter`.
		# Allow packages to alter defined routes.
		invoke(
			injectable, null
			routes: routes
		) for _, injectable of invokeWithMocks 'routeAlter'
		
		for path, route of routes
			do (path, route) ->
				
				# Wrap the controller so we can provide some automatic
				# behavior.
				# `TODO`: Define a routeController middleware stack for this.
				routeController = route.controller
				route.controller = [
					'$injector', '$scope', 'ui/title'
					({invoke}, $scope, title) ->
						
						title.setPage route.title ? ''
						
						invoke(
							routeController, null
							$scope: $scope
						)
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
exports.$appRun = -> [
	'$rootScope', '$location', '$window', 'socket'
	($rootScope, $location, $window, socket) ->
		
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
		
]

# ## Implements hook `routeMock`
# 
# A simple path definition to make sure we're running in e2e testing mode.
exports.$routeMock = -> path: 'e2e/sanity-check'
