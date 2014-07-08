
# # User register

errors = require 'errors'

# ## Implements hook `route`
exports.$route = ->
	
	title: 'Sign up'
	
	controller: [
		'$location', '$scope', 'shrub-ui/notifications', 'shrub-user'
		($location, $scope, {add}, {isLoggedIn}) ->
			return $location.path '/' if isLoggedIn()
				
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
						return if error?
				
						add(
							text: "An email has been sent with account registration details. Please check your email."
						)
						
						$location.path '/'
					
			$scope.$emit 'shrubFinishedRendering'
			
	]
	
	template: """

<div data-form="userRegister"></div>

"""
