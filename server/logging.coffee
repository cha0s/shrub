
# # Logging
#
# Provide a unified interface for logging information.

winston = require 'winston'

# ## .create
#
# *Create a new logger instance.*
#
# * (string) `filename` - The filename where the log will be written.
exports.create = (filename) ->

	new winston.Logger transports: [
		new winston.transports.Console level: 'warn', colorize: true
		new winston.transports.File level: 'silly', filename: filename
	]

# Create a default logger, for convenience.
defaultLogger = exports.create 'logs/shrub.log'
exports.defaultLogger = defaultLogger
