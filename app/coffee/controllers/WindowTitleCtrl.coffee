
$module.controller 'WindowTitleCtrl', [
	'$scope', 'title'
	($scope, title) ->
		
		$scope.title = title.window
		
]
