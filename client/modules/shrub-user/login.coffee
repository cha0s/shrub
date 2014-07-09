
# # User login

errors = require 'errors'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `routeMock`
	registrar.registerHook 'e2e', 'routeMock', ->
		
		path: 'e2e/user/login/:destination'
		
		controller: [
			'$location', '$routeParams', 'shrub-socket', 'shrub-user'
			($location, {destination}, socket, {fakeLogin}) ->
				
				fakeLogin('cha0s').then -> 
					$location.path "/user/#{destination}"
					
		]
		
	# ## Implements hook `transmittableError`
	registrar.registerHook 'transmittableError', exports.transmittableError
	
	# ## Implements hook `route`
	registrar.registerHook 'route', ->
		
		path: 'user/login'
		title: 'Sign in'
		
		controller: [
			'$location', '$scope', 'shrub-ui/notifications', 'shrub-user'
			($location, $scope, {add}, {isLoggedIn, login}) ->
				return $location.path '/' if isLoggedIn()
					
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
					
							login(
								'local'
								$scope.username
								$scope.password
	
							).then ->
								
								add(
									class: 'alert-success'
									text: "Logged in successfully."
								)
								
								$location.path '/'
				
				$scope.$emit 'shrubFinishedRendering'
				
		]
		
		template: """
	
<div data-shrub-form="userLogin"></div>

<a class="forgot" href="/user/forgot">Forgot your password?</a>
	
"""

# Transmittable login error.
LoginError = class LoginError extends errors.TransmittableError

	key: 'login'
	template: "No such username/password."

exports.transmittableError = -> LoginError