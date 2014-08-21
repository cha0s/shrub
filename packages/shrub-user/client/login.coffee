
# # User login

errors = require 'errors'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `routeMock`
	registrar.registerHook 'e2e', 'routeMock', ->
		
		path: 'e2e/user/login/:destination'
		
		controller: [
			'$location', '$routeParams', 'shrub-rpc', 'shrub-socket', 'shrub-user'
			($location, {destination}, rpc, socket, {fakeLogin}) ->
				
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
			($location, $scope, notifications, user) ->
				return $location.path '/' if user.isLoggedIn()
					
				$scope.userLogin =
					
					handlers: submit: [
					
						[
							'scope'
							(scope) ->
							
								user.login(
									'local'
									scope.username
									scope.password
								).then ->
									
									notifications.add(
										class: 'alert-success'
										text: 'Logged in successfully.'
									)
									
									$location.path '/'
						
						]
					
					]
					
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
