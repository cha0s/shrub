
errors = require 'errors'

exports.$route = ->
	
	path: 'user/reset/:token'
	title: 'Reset your password'
	
	controller: [
		'$location', '$routeParams', '$scope', 'ui/notifications'
		($location, $routeParams, $scope, notifications) ->
			
			$scope.userReset =
				
				password:
					type: 'password'
					label: "New password"
					required: true
				
				token:
					type: 'hidden'
					value: $routeParams.token
				
				submit:
					type: 'submit'
					label: "Reset password"
					rpc: true
					handler: (error, result) ->
						
						return notifications.add(
							class: 'alert-danger', text: errors.message error
						) if error?
				
						notifications.add text: "Password reset."
						$location.path '/'

			$scope.$emit 'shrubFinishedRendering'
			
	]
	
	template: """
	
<div data-form="userReset"></div>

"""
