# User login

    config = require 'config'

    {TransmittableError} = require 'errors'

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubTransmittableErrors`.

      registrar.registerHook 'shrubTransmittableErrors', exports.shrubTransmittableErrors

#### Implements hook `shrubAngularRoutes`.

      registrar.registerHook 'shrubAngularRoutes', ->

        routes = []

        if 'e2e' is config.get 'packageConfig:shrub-core:testMode'

          routes.push

            path: 'e2e/user/login/:destination'

            controller: [
              '$location', '$routeParams', 'shrub-rpc', 'shrub-socket', 'shrub-user'
              ($location, {destination}, rpc, socket, user) ->

                user.fakeLogin('cha0s').then ->
                  $location.path "/user/#{destination}"

            ]

        routes.push

          path: 'user/login'
          title: 'Sign in'

          controller: [
            '$location', '$scope', 'shrub-ui/messages', 'shrub-user'
            ($location, $scope, messages, user) ->
              return $location.path '/' if user.isLoggedIn()

              $scope.form =

                key: 'shrub-user-login'

###### TODO: Use rpc submission with a hidden 'method' field.

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

        return routes

Transmittable login error.

    class LoginError extends TransmittableError

      key: 'login'
      template: 'No such username/password.'

    exports.shrubTransmittableErrors = -> [
      LoginError
    ]
