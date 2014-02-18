
# User forgot password.
exports.$route =
	
	title: 'Forgot password'
	
	controller: [
		'$location', '$scope', 'ui/notifications', 'user'
		($location, $scope, notifications, user) ->
			
			$scope.userForgot =
				
				usernameOrEmail:
					type: 'text'
					label: "Username or Email"
					required: true
				
				submit:
					type: 'submit'
					label: "Email reset link"
					rpc: true
					handler: (error, result) ->
						
						return notifications.add(
							class: 'error', text: error.message
						) if error?
				
						notifications.add text: "You will be emailed a reset link."
						$location.path '/'
						
			user.isLoggedIn (isLoggedIn) ->
				return $location.path '/' if isLoggedIn
					
				$scope.$emit 'shrubFinishedRendering'
	]
	
	template: """

<div data-form="userForgot"></div>

"""
