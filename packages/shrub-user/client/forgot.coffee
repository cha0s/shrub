
# # User forgot password

errors = require 'errors'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `route`
	registrar.registerHook 'route', ->
		
		path: 'user/forgot'
		title: 'Forgot password'
		
		controller: [
			'$location', '$scope', 'shrub-ui/notifications', 'shrub-user'
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

<div data-shrub-form="userForgot"></div>

"""
