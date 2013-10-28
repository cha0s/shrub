
$module.controller 'formUserForgot', [
	'$location', '$scope', 'notifications', 'user'
	($location, $scope, notifications, user) ->
		
		$scope.submit = ->
			
			user.forgot(
				$scope.usernameOrEmail
			).then(
				->
					
					notifications.add text: "Request successful."
					$location.path '/'
					
				(error) -> notifications.add class: 'error', text: error.message
			)
		
]

$module.controller 'user/forgot', [
	'$scope', '$timeout', 'title'
	($scope, $timeout, title) ->
		
		title.setPage 'Forgot password'
		
		$timeout (-> $scope.$emit 'shrubFinishedRendering'), 25
		
]
