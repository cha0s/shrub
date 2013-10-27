
$module.controller 'formUserLogin', [
	'$element', '$location', '$scope', 'notifications', 'user'
	($element, $location, $scope, notifications, user) ->
		
		$scope.submit = ->
			
			user.login(
				'local'
				$scope.username
				$scope.password
			).then(
				(user) ->
					
					notifications.add text: "Logged in successfully."
					$location.path '/'
					
				(error) -> notifications.add class: 'error', text: error.message
			)
		
]

$module.controller 'user/login', [
	'$scope', '$timeout', 'title'
	($scope, $timeout, title) ->
		
		title.setPage 'Sign in'
		
		$timeout (-> $scope.$emit 'shrubFinishedRendering'), 25
		
]
