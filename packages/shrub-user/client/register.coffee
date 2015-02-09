
# # User register

exports.pkgmanRegister = (registrar) ->

  # ## Implements hook `route`
  registrar.registerHook 'route', ->

    path: 'user/register'
    title: 'Sign up'

    controller: [
      '$location', '$scope', 'shrub-ui/messages', 'shrub-rpc', 'shrub-user'
      ($location, $scope, messages, rpc, user) ->
        return $location.path '/' if user.isLoggedIn()

        $scope.form =

          key: 'shrub-user-register'

          submits: [

            rpc.formSubmitHandler (error, result) ->
              return if error?

              messages.add(
                text: 'An email has been sent with account registration details. Please check your email.'
              )

              $location.path '/'

          ]

          fields:

            username:
              type: 'text'
              label: 'Username'
              required: true

            email:
              type: 'email'
              label: 'Email'
              required: true

            submit:
              type: 'submit'
              value: 'Sign up'

    ]

    template: '''

<div
  data-shrub-form
  data-form="form"
></div>

'''
