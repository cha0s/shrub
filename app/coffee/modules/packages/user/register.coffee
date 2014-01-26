module.exports =

	$route:
		
		controller: [
			'$location', '$scope', 'notifications', 'title', 'user'
			($location, $scope, notifications, title, user) ->
				
				title.setPage 'Sign up'
				
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
						
				user.promise.then (user) -> 
				
					if user.id?
						
						$location.path '/'
					
					else
					
						$scope.$emit 'shrubFinishedRendering'
				
		]
		
		template: """
	
<div data-shrub-form="userRegister"></div>

"""

	$endpoint: (req, data, fn) ->
		
		crypto = require 'server/crypto'
		{models: User: User} = require 'server/jugglingdb'
		
		user = new User name: data.username
		
		# Encrypt the email.	
		crypto.encrypt data.email, (error, encryptedEmail) ->
			fn error if error?
		
			user.email = encryptedEmail
			
			# Generate hash salt.
			User.randomHash (error, salt) ->
				fn error if error?
				
				user.salt = salt
				
				# Don't reveal anything beyond any error.
				user.save (error, user) -> fn error
