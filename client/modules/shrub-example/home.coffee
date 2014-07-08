
# # Home page

# ## Implements hook `appConfig`
exports.$appConfig = -> [
	'$routeProvider'
	($routeProvider) ->
		
		# We'll gank the default route.
		$routeProvider.otherwise redirectTo: '/home'
]

# ## Implements hook `route`
exports.$route = ->

	path: 'home'
	title: 'Home'
	
	controller: [
		'$scope'
		($scope) ->
			
			$scope.$emit 'shrubFinishedRendering'
			
	]
	
	template: """

<div class="jumbotron">
	
	<h1>Shrub</h1>
	
	<p class="lead">Welcome to the example application for Shrub!</p>
	
	<hr>

</div>

"""
