
$module.controller 'PageTitleCtrl', [
	'$scope', 'title'
	($scope, title) ->
		
		$scope.title = title.page
		
]
