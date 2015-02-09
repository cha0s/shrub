
config = require 'config'

exports.pkgmanRegister = (registrar) ->

  # ## Implements hook `assetMiddleware`
  registrar.registerHook 'assetMiddleware', ->

    label: 'UI Bootstrap'
    middleware: [

      (assets, next) ->

        if 'production' is config.get 'NODE_ENV'

          assets.scripts.push '/lib/angular-ui/bootstrap/ui-bootstrap-tpls-0.10.0.min.js'

        else

          assets.scripts.push '/lib/angular-ui/bootstrap/ui-bootstrap-tpls-0.10.0.js'

        next()

    ]
