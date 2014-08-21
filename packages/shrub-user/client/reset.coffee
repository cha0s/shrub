
# # User reset

errors = require 'errors'

exports.pkgmanRegister = (registrar) ->
	
	# ## Implements hook `route`
	registrar.registerHook 'route', ->
		
		path: 'user/reset/:token'
		title: 'Reset your password'
		
		controller: [
			'$location', '$scope', 'shrub-ui/notifications', 'shrub-rpc'
			($location, $scope, notifications, rpc) ->
				
				$scope.userReset =
					
					handlers: submit: [
						
						rpc.formSubmitHandler (error, result) ->
							return if error?
							
							notifications.add(
								text: "You may now log in with your new password."
							)
							
							$location.path '/user/login'

					]
					
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
	
				$scope.$emit 'shrubFinishedRendering'
				
		]
		
		template: """
	
<div data-shrub-form="userReset"></div>

"""
