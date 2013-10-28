
$module.controller 'formUserRegister', [
	'$location', '$scope', 'notifications', 'user'
	($location, $scope, notifications, user) ->
		
		$scope.submit = ->
			
			user.register(
				$scope.username
				$scope.email
			).then(
				->
					
					notifications.add text: "Registered successfully."
					$location.path '/'
					
				(error) -> notifications.add class: 'error', text: error.message
			)
		
]

$module.controller 'user/register', [
	'$scope', '$timeout', 'title'
	($scope, $timeout, title) ->
		
		title.setPage 'Sign up'
		
		$timeout (-> $scope.$emit 'shrubFinishedRendering'), 25
		
]
