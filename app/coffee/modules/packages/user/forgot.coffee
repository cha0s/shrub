
# User forgot password.
module.exports =

	$route:
		
		controller: [
			'$location', '$scope', 'notifications', 'title'
			($location, $scope, notifications, title) ->
				
				title.setPage 'Forgot password'
				
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
							
							return notifications.add(
								class: 'error', text: error.message
							) if error?
					
							notifications.add text: "You will be emailed a reset link."
							$location.path '/'
							
				$scope.$emit 'shrubFinishedRendering'
		]
		
		template: """
	
<div data-shrub-form="userForgot"></div>

"""

	$endpoint: (req, data, fn) ->
		
		crypto = require 'server/crypto'
		Q = require 'q'
		
		{models: User: User} = require 'server/jugglingdb'
		
		deferred = Q.defer()
		
		# Search for username or encrypted email.
		if -1 is data.usernameOrEmail.indexOf '@'
			deferred.resolve where: name: data.usernameOrEmail
		else
			crypto.encrypt data.usernameOrEmail, (error, encryptedEmail) ->
				deferred.reject error if error?
				deferred.resolve where: email: encryptedEmail
		
		# fn() won't reveal anything.
		# Find the user.
		deferred.promise.then (filter) ->
			User.findOne filter, (error, user) ->
				return fn() if error?
				return fn() unless user
				
				# Generate a one-time login token.
				User.randomHash (error, hash) ->
					return fn() if error?
					
					user.resetPasswordToken = hash
					user.save ->
						
						# This would be where we send an email to the user
						# notifying them of the URL they can visit to reset
						# their password.
						
						fn()
						
		deferred.promise.fail (error) -> fn()				
