
exports.e2eLogin = $routeMock:
	
	path: 'e2e/user/login/:destination'
	
	controller: [
		'$location', '$routeParams', '$scope', 'comm/socket', 'user'
		($location, $routeParams, $scope, socket, user) ->
			
			socket.catchEmit 'rpc://user.login', (data, fn) ->
				fn result: id: 1, name: 'cha0s'
				
			user.login('local', 'cha0s', 'password').then (user) ->
				$location.path "/user/#{$routeParams.destination}"
				
	]
	
exports.e2eLoginLogout = $routeMock:
	
	path: 'e2e/user/login-logout'
	
	controller: [
		'$location', '$scope', 'comm/socket', 'user'
		($location, $scope, socket, user) ->
			
			socket.catchEmit 'rpc://user.login', (data, fn) ->
				fn result: id: 1, name: 'cha0s'
				
			socket.catchEmit 'rpc://user.logout', (data, fn) ->
				fn result: null
			
			user.login('local', 'cha0s', 'password').then ->
				user.logout().then ->
					$location.path "/user/login"
				
	]
	
exports.$route =
	
	title: 'Sign in'
	
	controller: [
		'$location', '$scope', 'ui/notifications', 'user'
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
			
			user.isLoggedIn (isLoggedIn) ->
				return $location.path '/' if isLoggedIn
					
				$scope.$emit 'shrubFinishedRendering'
			
	]
	
	template: """

<div data-core-form="userLogin"></div>

<a class="forgot" href="/user/forgot">Forgot your password?</a>

"""

exports.$endpoint = (req, fn) ->
	
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
