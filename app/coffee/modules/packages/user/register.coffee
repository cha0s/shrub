
exports.$route =
	
	title: 'Sign up'
	
	controller: [
		'$location', '$scope', 'notifications', 'user'
		($location, $scope, notifications, user) ->
			
			$scope.userRegister =
				
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
					rpc: true
					handler: (error, result) ->
						
						return notifications.add(
							class: 'error', text: error.message
						) if error?
				
						notifications.add text: "Registered successfully."
						$location.path '/'
					
			user.isLoggedIn (isLoggedIn) ->
				return $location.path '/' if isLoggedIn
					
				$scope.$emit 'shrubFinishedRendering'
			
	]
	
	template: """

<div data-shrub-form="userRegister"></div>

"""

exports.$endpoint = (req, fn) ->
	
	crypto = require 'server/crypto'
	{models: User: User} = require 'server/jugglingdb'
	
	user = new User name: req.body.username
	
	# Encrypt the email.	
	crypto.encrypt req.body.email, (error, encryptedEmail) ->
		fn error if error?
	
		user.email = encryptedEmail
		
		# Generate hash salt.
		User.randomHash (error, salt) ->
			fn error if error?
			
			user.salt = salt
			
			# Don't reveal anything beyond any error.
			user.save (error, user) -> fn error
