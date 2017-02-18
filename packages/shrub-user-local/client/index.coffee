
{TransmittableError} = require 'errors'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubTransmittableErrors`.
  registrar.registerHook 'shrubTransmittableErrors', exports.shrubTransmittableErrors

  # #### Implements hook `shrubUserLoginStrategies`.
  registrar.registerHook 'shrubUserLoginStrategies', ->

    exports.shrubUserLoginStrategies()

  registrar.recur [
    'email', 'forgot', 'register', 'reset'
  ]

exports.shrubUserLoginStrategies = ->

  methodLabel: 'Local'

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

    forgot:
      type: 'markup'
      value: '<a class="forgot" href="/user/local/forgot">Forgot your password?</a>'

exports.shrubOrmCollections = ->

  UserLocal =

    attributes:

      # Email address.
      email:
        type: 'string'
        index: true

      # Name.
      name:
        type: 'string'
        size: 24
        maxLength: 24

  'shrub-user-local': UserLocal

# Transmittable login error.
class LoginError extends TransmittableError

  errorType: 'shrub-user-local-login'
  template: 'No such username/password.'

exports.shrubTransmittableErrors = -> [
  LoginError
]
