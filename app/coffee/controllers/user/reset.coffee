
$module.controller 'formUserReset', [
	'$location', '$routeParams', '$scope', 'notifications', 'user'
	($location, $routeParams, $scope, notifications, user) ->
		
		$scope.submit = ->
			
			user.reset(
				$routeParams.token
				$scope.password
			).then(
				->
					
					notifications.add text: "Reset successfully."
					$location.path '/'
					
				(error) -> notifications.add class: 'error', text: error.message
			)
		
]

$module.controller 'user/reset', [
	'$scope', '$timeout', 'title'
	($scope, $timeout, title) ->
		
		title.setPage 'Reset your password'
		
		$timeout (-> $scope.$emit 'shrubFinishedRendering'), 25
		
]
