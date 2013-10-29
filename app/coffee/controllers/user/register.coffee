
$module.controller 'form-user-register', [
	'$location', '$scope', 'notifications', 'user'
	($location, $scope, notifications, user) ->

		$scope.form =
			
			username:
				type: 'text'
				title: "Username"
				required: true
			
			email:
				type: 'email'
				title: "Email"
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
	'$location', '$scope', 'title', 'user'
	($location, $scope, title, user) ->
		
		title.setPage 'Sign up'
		
		user.promise.then (user) -> 
		
			if user.id?
				$location.path '/'
			else
				$scope.$emit 'shrubFinishedRendering'
		
]
