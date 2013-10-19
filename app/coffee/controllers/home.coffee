
$module.controller 'home', [
	'$scope', 'title'
	($scope, title) ->
		
		title.setPage 'Home'
		
		$scope.$emit 'shrubFinishedRendering'
		
]
