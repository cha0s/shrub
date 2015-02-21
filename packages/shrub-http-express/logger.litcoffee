# Express - logger

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `httpMiddleware`.

Log requests, differentiating between client and sandbox requests.

      registrar.registerHook 'httpMiddleware', (http) ->

        express = require 'express'

        logging = require 'logging'

Differentiate between remote clients and our own sandbox clients.

        remoteRequestLogger = logging.create 'logs/express.remote.log'
        sandboxRequestLogger = logging.create 'logs/express.sandbox.log'

        label: 'Log requests'
        middleware: [

          express.logger stream:
            write: (message, encoding) ->

              logger = if message.match /(http:\/\/localhost:|node-XMLHttpRequest)/
                sandboxRequestLogger
              else
                remoteRequestLogger

              logger.info message

        ]
