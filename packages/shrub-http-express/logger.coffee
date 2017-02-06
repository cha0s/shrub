# # Express - logger
morgan = require 'morgan'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubHttpMiddleware`.
  #
  # Log requests, differentiating between client and sandbox requests.
  registrar.registerHook 'shrubHttpMiddleware', (http) ->

    express = require 'express'

    logging = require 'logging'

    # Differentiate between remote clients and our own sandbox clients.
    remoteRequestLogger = logging.create 'logs/express.remote.log'
    sandboxRequestLogger = logging.create 'logs/express.sandbox.log'

    label: 'Log requests'
    middleware: [

      morgan 'combined', stream:
        write: (message, encoding) ->

          logger = if message.match /(http:\/\/localhost:|node-XMLHttpRequest)/
            sandboxRequestLogger
          else
            remoteRequestLogger

          logger.info message

    ]