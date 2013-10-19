
$module.controller 'windowTitle', [
	'$scope', 'title'
	($scope, title) ->
		
		$scope.title = title.window
		
]
