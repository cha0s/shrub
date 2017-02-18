# # User Interface

errors = require 'errors'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubConfigClient`.
  registrar.registerHook 'shrubConfigClient', (req) ->
    config = {}

    if req.session?

      errorMessages = req.session.errorMessages ? []
      delete req.session.errorMessages
      config.errorMessages = errorMessages

    return config

  registrar.recur [
    'notifications'
  ]