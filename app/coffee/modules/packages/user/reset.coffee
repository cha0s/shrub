
exports.$route =
		
	title: 'Reset your password'
	
	controller: [
		'$location', '$scope', 'notifications'
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
							class: 'error', text: error.message
						) if error?
				
						notifications.add text: "Password reset."
						$location.path '/'

			$scope.$emit 'shrubFinishedRendering'
			
	]
	
	template: """
	
<div data-shrub-form="userReset"></div>

"""

	params: ['token']

exports.$endpoint = (req, fn) ->
	
	crypto = require 'server/crypto'
	{models: User: User} = require 'server/jugglingdb'
	
	filter = where: resetPasswordToken: req.body.token
	
	# It may seem strange that we merely invoke fn() instead of sending
	# useful data to the client, but the reasoning behind this is to make it
	# impossible to tell whether an invalid token was used.
	User.findOne filter, (error, user) ->
		return fn() if error?
		return fn() unless user
		
		User.hashPassword req.body.password, user.salt, (error, passwordHash) ->
			return fn() if error?
			
			user.passwordHash = passwordHash
			user.resetPasswordToken = null
			user.save -> fn()
