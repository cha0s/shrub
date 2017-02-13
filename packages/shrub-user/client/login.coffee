# # User login
config = require 'config'
pkgman = require 'pkgman'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubAngularRoutes`.
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

          strategies = pkgman.invoke 'shrubUserLoginStrategies'
          strategiesCount = pkgman.packagesImplementing(
            'shrubUserLoginStrategies'
          ).length

          $scope.form =

            key: 'shrub-user-login'

            fields: {}

            submits: [

              (values) ->

                methodValues = values[values.method]
                methodValues.method = values.method

                # console.log values
                # return

                user.login(methodValues).then ->

                  messages.add(
                    class: 'alert-success'
                    text: 'Logged in successfully.'
                  )

                  # $location.path '/'

            ]

          # No strategies? Bail.
          return $location.path '/' if strategiesCount is 0

          fields = $scope.form.fields

          if strategiesCount is 1

            method = packageName for packageName, strategy of strategies

            fields.method =
              type: 'hidden'
              value: method

          else

            fields.method =
              type: 'select'
              label: 'Method'
              options: 'key as value for (key , value) in field.methodOptions'

            fields.method.methodOptions = {}
            for packageName, {methodLabel} of strategies
              fields.method.value = packageName unless fields.method.value?
              fields.method.methodOptions[packageName] = methodLabel

          for packageName, strategy of strategies

            $scope.form.fields[packageName] =

              type: 'group'
              collapse: false
              fields: strategy.fields

      ]

      template: '''

<div
  data-shrub-form
  data-form="form"
></div>

'''

    return routes
