
$module.controller 'AboutCtrl', [
	'$http', '$scope', 'title'
	($http, $scope, title) ->
		
		title.setPage 'About'
		
		# Load the about page asynchronously.
		$scope.about = ' '
		promise = $http method: 'GET', url: '/partials/about.md'
		
		promise.success (data, status, headers, config) -> $scope.about = data
		
		promise.error (data, status, headers, config) ->
			$scope.about = "Weird, loading the about page failed. Try refreshing."
			
		promise.finally -> $scope.$emit 'shrubFinishedRendering'
		
]
