
module.exports =

	$route:
		
		controller: [
			'$location', '$scope', 'notifications', 'title', 'user'
			($location, $scope, notifications, title, user) ->
				
				title.setPage 'Sign in'
				
				$scope.userLoginForm =
					
					username:
						type: 'text'
						title: "Username"
						required: true
					
					password:
						type: 'password'
						title: "Password"
						required: true
					
					submit:
						type: 'submit'
						title: "Sign in"
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
	
<div data-shrub-form="userLoginForm"></div>

<a class="forgot" href="/user/forgot">Forgot your password?</a>

"""

	$endpoint: (req, data, fn) ->
		
		{models: User: User} = require 'server/jugglingdb'
		
		passport = req._passport.instance
		req.body = data
				
		switch data.method
			
			when 'local'
				
				(passport.authenticate 'local', (error, user, info) ->
					return fn attempted: error.message if error?
					return fn code: 420 unless user
					
					req.login user, (error) ->
						return fn attempted: error.message if error?
						fn null, user
				
				) req, res = {}
