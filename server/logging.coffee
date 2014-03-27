
# # Logging
# 
# Provide a unified interface for logging information.

nconf = require 'nconf'
winston = require 'winston'

# ## .create
# 
# *Create a new logger instance.*
# 
# * (string) `filename` - The filename where the log will be written.
exports.create = (filename) ->
	
	# In production, we'll only log errors to the file, and skip console output
	# altogether.
	transports = if 'production' is process.env.NODE_ENV

		[
			new winston.transports.File level: 'error', filename: filename
		]
		
	# Otherwise, we will show ALL the logs, in the console as well as in their
	# files.
	else

		[
			new winston.transports.Console level: 'silly', colorize: true
			new winston.transports.File level: 'silly', filename: filename
		]
		
	new winston.Logger transports: transports

# Create a default logger, for convenience.
defaultLogger = exports.create 'logs/shrub.log'
exports.defaultLogger = defaultLogger
