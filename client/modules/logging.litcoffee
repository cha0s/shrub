# Logging

*A unified interface for logging information.*

###### TODO: This isn't much use on the client. To properly log, we would have to hook into localStorage.

    config = require 'config'

## logger.create

* (string) `type` - The type of log.

*Create a new logger instance.*

    exports.create = (type) ->

      augmentedConsoleFunction = (key) -> ->
        args = (arg for arg in arguments)
        args.unshift type
        console[key].apply console, args

      logger = {}
      logger[key] = augmentedConsoleFunction key for key in [
        'debug', 'error', 'info', 'log', 'warn'
      ]
      logger

## logger.defaultLogger

*Create a default logger, for convenience.*

    defaultLogger = exports.create 'shrub'
    exports.defaultLogger = defaultLogger
