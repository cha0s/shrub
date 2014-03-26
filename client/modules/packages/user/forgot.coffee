
# # User forgot password

errors = require 'errors'

# ## Implements hook `route`
exports.$route = ->
	
	title: 'Forgot password'
	
	controller: [
		'$location', '$scope', 'ui/notifications', 'user'
		($location, $scope, {add}, {isLoggedIn}) ->
			return $location.path '/' if isLoggedIn()
				
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
						
						add(
							text: "A reset link will be emailed."
						)
						
						$location.path '/'
						
			$scope.$emit 'shrubFinishedRendering'
	]
	
	template: """

<div data-form="userForgot"></div>

"""
