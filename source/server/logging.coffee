# Server logging

*Provide a unified interface for logging messages.*

## logging.create

* (string) `filename` - The filename where the log will be written.

*Create a new logger instance.*

```coffeescript
exports.create = (filename) ->

  winston = require 'winston'

  new winston.Logger transports: [
    new winston.transports.Console level: 'warn', colorize: true
    new winston.transports.File level: 'silly', filename: filename
  ]
```

Create a default logger, for convenience.

```coffeescript
defaultLogger = exports.create 'logs/shrub.log'
exports.defaultLogger = defaultLogger
```
