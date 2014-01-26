
module.exports =

	$route:
		
		title: 'Sign in'
		
		controller: [
			'$location', '$scope', 'notifications', 'user'
			($location, $scope, notifications, user) ->
				
				$scope.userLogin =
					
					username:
						type: 'text'
						label: "Username"
						required: true
					
					password:
						type: 'password'
						label: "Password"
						required: true
					
					submit:
						type: 'submit'
						label: "Sign in"
						handler: ->
					
							user.login(
								'local'
								$scope.username
								$scope.password
							).then(
								
								->
									notifications.add text: "Logged in successfully."
									$location.path '/'
									
								(error) -> notifications.add(
									class: 'error', text: error.message
								)
							)
				
				user.promise.then (user) -> 
				
					# Already logged in?
					if user.id?
						$location.path '/'
					
					else
					
						$scope.$emit 'shrubFinishedRendering'
				
		]
		
		template: """
	
<div data-shrub-form="userLogin"></div>

<a class="forgot" href="/user/forgot">Forgot your password?</a>

"""

	$endpoint: (req, fn) ->
		
		{models: User: User} = require 'server/jugglingdb'
		
		switch req.body.method
			
			when 'local'
				
				(req.passport.authenticate 'local', (error, user, info) ->
					return fn attempted: error.message if error?
					return fn code: 420 unless user
					
					req.login user, (error) ->
						return fn attempted: error.message if error?
						fn null, user
				
				) req, res = {}
