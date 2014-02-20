
exports.$route =
	
	title: 'Sign up'
	
	controller: [
		'$location', '$scope', 'ui/notifications', 'user'
		($location, $scope, notifications, user) ->
			return $location.path '/' if user.isLoggedIn()
				
			$scope.userRegister =
				
				username:
					type: 'text'
					label: "Username"
					required: true
				
				email:
					type: 'email'
					label: "Email"
					required: true
				
				submit:
					type: 'submit'
					label: "Register"
					rpc: true
					handler: (error, result) ->
						
						return notifications.add(
							class: 'error', text: error.message
						) if error?
				
						notifications.add text: "Registered successfully."
						$location.path '/'
					
			$scope.$emit 'shrubFinishedRendering'
			
	]
	
	template: """

<div data-form="userRegister"></div>

"""
