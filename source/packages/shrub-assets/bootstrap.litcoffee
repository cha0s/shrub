# Bootstrap assets

    config = require 'config'

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `assetScriptMiddleware`.

      registrar.registerHook 'assetScriptMiddleware', ->

        label: 'Bootstrap'
        middleware: [

          (req, res, next) ->

            if 'production' is config.get 'NODE_ENV'

              res.locals.scripts.push '/lib/bootstrap/js/bootstrap.min.js'

            else

              res.locals.scripts.push '/lib/bootstrap/js/bootstrap.js'

            next()

        ]
