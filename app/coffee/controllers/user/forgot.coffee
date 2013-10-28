
$module.controller 'form-user-forgot', [
	'$location', '$scope', 'notifications', 'user'
	($location, $scope, notifications, user) ->
		
		$scope.form =
			
			usernameOrEmail:
				type: 'text'
				title: "Username or Email"
				required: true
			
			submit:
				type: 'submit'
				title: "Email reset link"
				handler: ->
			
					user.forgot(
						$scope.usernameOrEmail
					).then(

						->
							notifications.add text: "You will be emailed a reset link."
							$location.path '/'
							
						(error) -> notifications.add(
							class: 'error', text: error.message
						)
					)
		
]

$module.controller 'user/forgot', [
	'$scope', 'title'
	($scope, title) ->
		
		title.setPage 'Forgot password'
		
		$scope.$emit 'shrubFinishedRendering'
		
]
