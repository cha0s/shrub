# # Server logging
#
# *Provide a unified interface for logging messages.*

_ = require 'lodash'

util = require 'util'

config = require 'config'
errors = require 'errors'

debug = require('debug') 'shrub:logger'

# ## logging.create
#
# * (string) `filename` - The filename where the log will be written.
#
# *Create a new logger instance.*
exports.create = (options) ->

  winston = require 'winston'
  {Transport} = require 'winston/lib/winston/transports/transport'

  class DebugTransport extends Transport

    log: (level, msg, meta, callback) ->

      output = "#{level}: "
      output += if _.isString msg
        msg
      else
        util.inspect msg
      output += errors.stack meta if meta instanceof Error

      debug output

      @emit 'logged'
      callback null, true

  options ?= {}
  options.transports ?= []

  options.console ?= {}
  options.console.level ?= if 'production' is config.get 'NODE_ENV'
    'error'
  else
    'silly'
  options.transports.push new DebugTransport options.console

  options.file ?= {}
  options.file.level ?= if 'production' is config.get 'NODE_ENV'
    'error'
  else
    'silly'
  options.file.json ?= false
  if options.file.filename?
    options.transports.push new winston.transports.File options.file

  new winston.Logger transports: options.transports

# Create a default logger, for convenience.
defaultLogger = exports.create file: filename: 'logs/shrub.log'
exports.defaultLogger = defaultLogger
