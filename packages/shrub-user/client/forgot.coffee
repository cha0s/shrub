
# # User forgot password

errors = require 'errors'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `route`
	registrar.registerHook 'route', ->
		
		path: 'user/forgot'
		title: 'Forgot password'
		
		controller: [
			'$location', '$scope', 'shrub-ui/notifications', 'shrub-rpc', 'shrub-user'
			($location, $scope, notifications, rpc, user) ->
				return $location.path '/' if user.isLoggedIn()
				
				$scope.userForgot =
					
					handlers: submit: [
						
						rpc.formSubmitHandler (error, result) ->
							return if error?
							
							notifications.add(
								text: "A reset link will be emailed."
							)
							
							$location.path '/'

					]
					
					usernameOrEmail:
						type: 'text'
						label: "Username or Email"
						required: true
					
					submit:
						type: 'submit'
						label: "Email reset link"
							
				$scope.$emit 'shrubFinishedRendering'
		]
		
		template: """

<div data-shrub-form="userForgot"></div>

"""
