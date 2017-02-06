# # User - Reset password
errors = require 'errors'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubAngularRoutes`.
  registrar.registerHook 'shrubAngularRoutes', ->

    routes = []

    routes.push

      path: 'user/reset/:token'
      title: 'Reset your password'

      controller: [
        '$location', '$routeParams', '$scope', 'shrub-ui/messages', 'shrub-rpc'
        ($location, $routeParams, $scope, messages, rpc) ->

          $scope.form =

            key: 'shrub-user-reset'

            submits: [

              rpc.formSubmitHandler 'shrub-user/reset', (error, result) ->
                return if error?

                messages.add(
                  text: 'You may now log in with your new password.'
                )

                $location.path '/user/login'

            ]

            fields:

              password:
                type: 'password'
                label: 'New password'
                required: true

              token:
                type: 'hidden'
                value: $routeParams.token

              submit:
                type: 'submit'
                value: 'Reset password'

      ]

      template: '''

<div
  data-shrub-form
  data-form="form"
></div>

'''

    return routes