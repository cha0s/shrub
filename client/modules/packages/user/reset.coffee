
errors = require 'errors'

exports.$route =
	
	path: 'user/reset/:token'
	title: 'Reset your password'
	
	controller: [
		'$location', '$scope', 'ui/notifications'
		($location, $scope, notifications) ->
			
			$scope.userReset =
				
				password:
					type: 'password'
					label: "New password"
					required: true
				
				submit:
					type: 'submit'
					label: "Reset password"
					rpc: true
					handler: (error, result) ->
						
						return notifications.add(
							class: 'error', text: errors.message error
						) if error?
				
						notifications.add text: "Password reset."
						$location.path '/'

			$scope.$emit 'shrubFinishedRendering'
			
	]
	
	template: """
	
<div data-form="userReset"></div>

"""
