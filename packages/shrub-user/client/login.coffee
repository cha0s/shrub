
# # User login

errors = require 'errors'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `routeMock`
	registrar.registerHook 'e2e', 'routeMock', ->

		path: 'e2e/user/login/:destination'

		controller: [
			'$location', '$routeParams', 'shrub-rpc', 'shrub-socket', 'shrub-user'
			($location, {destination}, rpc, socket, user) ->

				user.fakeLogin('cha0s').then ->
					$location.path "/user/#{destination}"

		]

	# ## Implements hook `transmittableError`
	registrar.registerHook 'transmittableError', exports.transmittableError

	# ## Implements hook `route`
	registrar.registerHook 'route', ->

		path: 'user/login'
		title: 'Sign in'

		controller: [
			'$location', '$scope', 'shrub-ui/messages', 'shrub-user'
			($location, $scope, messages, user) ->
				return $location.path '/' if user.isLoggedIn()

				$scope.form =

					key: 'shrub-user-login'

					submits: [

						(values) ->

							user.login(
								'local'
								values.username
								values.password
							).then ->

								messages.add(
									class: 'alert-success'
									text: 'Logged in successfully.'
								)

								$location.path '/'

					]

					fields:

						username:
							type: 'text'
							label: 'Username'
							required: true

						password:
							type: 'password'
							label: 'Password'
							required: true

						submit:
							type: 'submit'
							value: 'Sign in'

		]

		template: '''

<div
	data-shrub-form
	data-form="form"
></div>

<a class="forgot" href="/user/forgot">Forgot your password?</a>

'''

# Transmittable login error.
LoginError = class LoginError extends errors.TransmittableError

	key: 'login'
	template: 'No such username/password.'

exports.transmittableError = -> LoginError
