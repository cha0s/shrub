
$module.controller 'HomeCtrl', [
	'$scope', 'title'
	($scope, title) ->
		
		title.setPage 'Home'
		
		$scope.$emit 'shrubFinishedRendering'
		
]
