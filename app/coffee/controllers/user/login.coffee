
$module.controller 'form-user-login', [
	'$location', '$scope', 'notifications', 'user'
	($location, $scope, notifications, user) ->
		
		$scope.form =
			
			username:
				title: "Username"
				type: 'text'
				required: true
			
			password:
				title: "Password"
				type: 'password'
				required: true
			
			submit:
				type: 'submit'
				title: "Sign in"
				handler: ->
			
					user.login(
						'local'
						$scope.username
						$scope.password
					).then(
						
						->
							notifications.add text: "Logged in successfully."
							$location.path '/'
							
						(error) -> notifications.add(
							class: 'error', text: error.message
						)
					)
		
]

$module.controller 'user/login', [
	'$scope', 'title'
	($scope, title) ->
		
		title.setPage 'Sign in'
		
		$scope.$emit 'shrubFinishedRendering'
		
]
