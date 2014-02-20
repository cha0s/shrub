
exports.e2eLogin = $routeMock:
	
	path: 'e2e/user/login/:destination'
	
	controller: [
		'$location', '$routeParams', '$scope', 'socket', 'user'
		($location, $routeParams, $scope, socket, user) ->
			
			socket.catchEmit 'rpc://user.login', (data, fn) ->
				fn result: id: 1, name: 'cha0s'
				
			user.login('local', 'cha0s', 'password').then (user) ->
				$location.path "/user/#{$routeParams.destination}"
				
	]
	
exports.$route =
	
	title: 'Sign in'
	
	controller: [
		'$location', '$scope', 'ui/notifications', 'user'
		($location, $scope, notifications, user) ->
			return $location.path '/' if user.isLoggedIn()
				
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
			
			$scope.$emit 'shrubFinishedRendering'
			
	]
	
	template: """

<div data-form="userLogin"></div>

<a class="forgot" href="/user/forgot">Forgot your password?</a>

"""
