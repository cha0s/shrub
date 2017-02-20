# # Express - logger

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubHttpMiddleware`.
  #
  # Log requests, differentiating between client and sandbox requests.
  registrar.registerHook 'shrubHttpMiddleware', (http) ->

    os = require 'os'

    express = require 'express'
    morgan = require 'morgan'

    logging = require 'logging'

    # Differentiate between remote clients and our own sandbox clients.
    remoteRequestLogger = logging.create(
      file: filename: 'logs/express.remote.log', level: 'info'
    )
    sandboxRequestLogger = logging.create(
      file: filename: 'logs/express.local.log', level: 'info'
    )

    label: 'Log requests'
    middleware: [

      morgan 'combined', stream:
        write: (message, encoding) ->

          logger = if message.match ///
            (
              https?:\/\/(?:
                localhost
                | 127\.0\.0\.1
                | ::ffff:127\.0\.0\.1
                | ::1
              )
              | node-XMLHttpRequest
              | Node\.js
            )
          ///
            sandboxRequestLogger
          else
            remoteRequestLogger

          logger.info message.substr 0, message.length - os.EOL.length

    ]