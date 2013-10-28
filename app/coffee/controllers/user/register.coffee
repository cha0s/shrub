
$module.controller 'form-user-register', [
	'$location', '$scope', 'notifications', 'user'
	($location, $scope, notifications, user) ->

		$scope.form =
			
			username:
				title: "Username"
				type: 'text'
				required: true
			
			email:
				title: "Email"
				type: 'email'
				required: true
			
			submit:
				type: 'submit'
				title: "Register"
				handler: ->
			
					user.register(
						$scope.username
						$scope.email
					).then(

						->
							notifications.add text: "Registered successfully."
							$location.path '/'
							
						(error) -> notifications.add(
							class: 'error', text: error.message
						)
					)
		
]

$module.controller 'user/register', [
	'$scope', 'title'
	($scope, title) ->
		
		title.setPage 'Sign up'
		
		$scope.$emit 'shrubFinishedRendering'
		
]
