# Auditing

*Track users through the request. This can be used to weed out bad behavior,
for analytics, or anything else.*

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubHttpMiddleware`.

      registrar.registerHook 'shrubHttpMiddleware', (http) ->

        label: 'Store fingerprint'
        middleware: [

          (req, res, next) ->

            req.fingerprint = new exports.Fingerprint req

            next()

        ]

#### Implements hook `shrubSocketConnectionMiddleware`.

      registrar.registerHook 'shrubSocketConnectionMiddleware', (http) ->

        label: 'Store fingerprint'
        middleware: [

          (req, res, next) ->

            req.fingerprint = new exports.Fingerprint req

            next()

        ]

    exports.Fingerprint = require './fingerprint'
