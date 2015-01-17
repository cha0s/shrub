
# # User register

errors = require 'errors'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `route`
	registrar.registerHook 'route', ->
		
		path: 'user/register'
		title: 'Sign up'
		
		controller: [
			'$location', '$scope', 'shrub-ui/notifications', 'shrub-rpc', 'shrub-user'
			($location, $scope, notifications, rpc, user) ->
				return $location.path '/' if user.isLoggedIn()
					
				$scope.form =
					
					key: 'shrub-user-register'
					
					submits: [
						
						rpc.formSubmitHandler (error, result) ->
							return if error?
							
							notifications.add(
								text: "An email has been sent with account registration details. Please check your email."
							)
							
							$location.path '/'

					]
					
					fields:
					
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
						
		]
		
		template: """
	
<div
	data-shrub-form
	data-form="form"
></div>

"""
