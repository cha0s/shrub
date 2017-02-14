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

          # #### Invoke hook `shrubUserLoginStrategies`.
          strategies = pkgman.invoke 'shrubUserLoginStrategies'

          # Count the active strategies.
          strategiesCount = pkgman.packagesImplementing(
            'shrubUserLoginStrategies'
          ).length

          # Build the login form.
          $scope.form =

            key: 'shrub-user-login'

            submits: [

              (values) ->

                # Extract the values from the active strategy's fieldgroup.
                methodValues = values[values.method]

                # Manually inject the method into the strategy values.
                methodValues.method = values.method

                # Attempt the login.
                user.login(methodValues).then ->

                  # Notify user.
                  messages.add(
                    class: 'alert-success'
                    text: 'Logged in successfully.'
                  )

                  # Redirect to root.
                  $location.path '/'

            ]

          # No strategies? Bail.
          return $location.path '/' if strategiesCount is 0

          # DRY
          fields = $scope.form.fields = {}

          # If there's only one strategy active, simply inject the `method`
          # into the form as a hidden field.
          if strategiesCount is 1

            method = packageName for packageName, strategy of strategies

            fields.method =
              type: 'hidden'
              value: method

          # If there's more than one method, use a dropdown to select the
          # login strategy.
          #
          # ###### TODO: This is janky from UX perspective. Rely on skin? At least hide inactive strategies' fieldgroups...
          else

            fields.method =
              type: 'select'
              label: 'Method'
              options: 'key as value for (key , value) in field.methodOptions'

            # Build the options list.
            fields.method.methodOptions = {}
            for packageName, {methodLabel} of strategies

              # Start the select with the first value, otherwise Angular
              # will inject a blank element.
              fields.method.value = packageName unless fields.method.value?

              # Use the strategy labels.
              fields.method.methodOptions[packageName] = methodLabel

          # Inject a fieldgroup for every login strategy.
          fields[packageName] = {
            type: 'group'
            collapse: false
            fields: strategy.fields
          } for packageName, strategy of strategies

      ]

      template: '''

<div
  data-shrub-form
  data-form="form"
></div>

'''

    return routes
