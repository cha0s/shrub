
errors = require 'errors'

exports.e2eLogin = $routeMock: ->
	
	path: 'e2e/user/login/:destination'
	
	controller: [
		'$location', '$routeParams', '$scope', 'socket', 'user'
		($location, $routeParams, $scope, socket, user) ->
			
			user.fakeLogin('cha0s').then ->
				$location.path "/user/#{$routeParams.destination}"
				
	]
	
LoginError = class LoginError extends errors.BaseError

	key: 'login'
	template: "No such username/password."
		
exports.$errorType = -> LoginError

exports.$route = ->
	
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

						).then ->
							
							notifications.add(
								class: 'alert-success'
								text: "Logged in successfully."
							)
							
							$location.path '/'
			
			$scope.$emit 'shrubFinishedRendering'
			
	]
	
	template: """

<div data-form="userLogin"></div>

<a class="forgot" href="/user/forgot">Forgot your password?</a>

"""
