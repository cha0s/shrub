# Express - static files

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `httpMiddleware`.

Serve static files.

      registrar.registerHook 'httpMiddleware', (http) ->

        express = require 'express'

        config = require 'config'

        label: 'Serve static files'
        middleware: [
          express.static config.get 'packageSettings:shrub-http:path'
        ]
