# User - Forgot password
```coffeescript
exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubAngularRoutes`.
```coffeescript
  registrar.registerHook 'shrubAngularRoutes', ->

    routes = []

    routes.push

      path: 'user/local/forgot'
      title: 'Forgot password'

      controller: [
        '$location', '$scope', 'shrub-ui/messages', 'shrub-rpc', 'shrub-user'
        ($location, $scope, messages, rpc, user) ->
          return $location.path '/' if user.isLoggedIn()

          $scope.form =

            key: 'shrub-user-local-forgot'

            submits: [

              rpc.formSubmitHandler 'shrub-user/local/forgot', (error, result) ->
                return if error?

                messages.add(
                  text: 'A reset link will be emailed.'
                )

                $location.path '/'

            ]

            fields:

              usernameOrEmail:
                type: 'text'
                label: 'Username or Email'
                required: true

              submit:
                type: 'submit'
                value: 'Email reset link'

      ]

      template: '''

<div
  data-shrub-form
  data-form="form"
></div>

'''

    return routes
```
