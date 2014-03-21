
nconf = require 'nconf'
winston = require 'winston'

winston = require 'winston'

exports.create = (filename) ->
	
	transports = if 'production' is process.env.NODE_ENV

		[
			new winston.transports.File level: 'error', filename: filename
		]
		
	else

		[
			new winston.transports.Console level: 'silly', colorize: true
			new winston.transports.File level: 'silly', filename: filename
		]
		
	new winston.Logger transports: transports

defaultLogger = exports.create 'logs/shrub.log'
exports.defaultLogger = defaultLogger
