module.exports =

	$route:
		
		controller: [
			'$location', '$routeParams', '$scope', 'notifications', 'title', 'user'
			($location, $routeParams, $scope, notifications, title, user) ->
				
				title.setPage 'Reset your password'
				
				$scope.userResetForm =
					
					password:
						type: 'password'
						title: "New password"
						required: true
					
					submit:
						type: 'submit'
						title: "Reset password"
						handler: ->
					
							user.reset(
								$routeParams.token
								$scope.password
							).then(
		
								->
									notifications.add text: "Password reset."
									$location.path '/'
									
								(error) -> notifications.add(
									class: 'error', text: error.message
								)
							)
				
				$scope.$emit 'shrubFinishedRendering'
				
		]
		
		template: """
	
<div data-shrub-form="userResetForm"></div>

"""

	$endpoint: (req, data, fn) ->
		
		crypto = require 'server/crypto'
		{models: User: User} = require 'server/jugglingdb'
		
		filter = where: resetPasswordToken: data.token
		
		# It may seem strange that we merely invoke fn() instead of sending
		# useful data to the client, but the reasoning behind this is to make it
		# impossible to tell whether an invalid token was used.
		User.findOne filter, (error, user) ->
			return fn() if error?
			return fn() unless user
			
			User.hashPassword data.password, user.salt, (error, passwordHash) ->
				return fn() if error?
				
				user.passwordHash = passwordHash
				user.resetPasswordToken = null
				user.save -> fn()
