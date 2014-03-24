
errors = require 'errors'

# User forgot password.
exports.$route = ->
	
	title: 'Forgot password'
	
	controller: [
		'$location', '$scope', 'ui/notifications', 'user'
		($location, $scope, notifications, user) ->
			return $location.path '/' if user.isLoggedIn()
				
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
						return if error?
						
						notifications.add(
							text: "A reset link will be emailed."
						)
						
						$location.path '/'
						
			$scope.$emit 'shrubFinishedRendering'
	]
	
	template: """

<div data-form="userForgot"></div>

"""