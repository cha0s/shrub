
# # User reset

errors = require 'errors'

exports.pkgmanRegister = (registrar) ->
	
	# ## Implements hook `route`
	registrar.registerHook 'route', ->
		
		path: 'user/reset/:token'
		title: 'Reset your password'
		
		controller: [
			'$location', '$routeParams', '$scope', 'shrub-ui/notifications'
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
	
<div data-shrub-form="userReset"></div>

"""
