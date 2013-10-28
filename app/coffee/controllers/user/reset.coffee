
$module.controller 'form-user-reset', [
	'$location', '$routeParams', '$scope', 'notifications', 'user'
	($location, $routeParams, $scope, notifications, user) ->
		
		$scope.form =
			
			password:
				type: 'password'
				title: "New password"
				required: true
			
			submit:
				type: 'submit'
				title: "Reset password"
				handler: ->
			
					user.reset(
						$routeParams.token
						$scope.password
					).then(

						->
							notifications.add text: "Password reset."
							$location.path '/'
							
						(error) -> notifications.add(
							class: 'error', text: error.message
						)
					)
		
]

$module.controller 'user/reset', [
	'$scope', 'title'
	($scope, title) ->
		
		title.setPage 'Reset your password'
		
		$scope.$emit 'shrubFinishedRendering'
		
]
