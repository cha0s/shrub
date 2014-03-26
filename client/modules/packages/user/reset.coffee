
# # User reset

errors = require 'errors'

# ## Implements hook `route`
exports.$route = ->
	
	path: 'user/reset/:token'
	title: 'Reset your password'
	
	controller: [
		'$location', '$routeParams', '$scope', 'ui/notifications'
		($location, {token}, $scope, {add}) ->
			
			$scope.userReset =
				
				password:
					type: 'password'
					label: "New password"
					required: true
				
				token:
					type: 'hidden'
					value: token
				
				submit:
					type: 'submit'
					label: "Reset password"
					rpc: true
					handler: (error, result) ->
						return if error?
						
						add text: "You may now log in with your new password."
						
						$location.path '/user/login'

			$scope.$emit 'shrubFinishedRendering'
			
	]
	
	template: """
	
<div data-form="userReset"></div>

"""
