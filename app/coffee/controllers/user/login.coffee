
$module.controller 'form-user-login', [
	'$location', '$scope', 'notifications', 'user'
	($location, $scope, notifications, user) ->
		
		user.promise.then (user) -> unless user.id? $location.path '/'
		
		$scope.form =
			
			username:
				type: 'text'
				title: "Username"
				required: true
			
			password:
				type: 'password'
				title: "Password"
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
