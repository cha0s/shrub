
exports.pkgmanRegister = (registrar) ->

  # ## Implements hook `httpMiddleware`
  registrar.registerHook 'httpMiddleware', (http) ->

    label: 'Store fingerprint'
    middleware: [

      (req, res, next) ->

        req.fingerprint = new exports.Fingerprint req

        next()

    ]

  # ## Implements hook `socketAuthorizationMiddleware`
  registrar.registerHook 'socketAuthorizationMiddleware', (http) ->

    label: 'Store fingerprint'
    middleware: [

      (req, res, next) ->

        req.fingerprint = new exports.Fingerprint req

        next()

    ]

exports.Fingerprint = require './fingerprint'
