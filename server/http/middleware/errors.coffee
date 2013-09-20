
express = require 'express'
winston = require 'winston'

logger = new winston.Logger
	transports: [
		new winston.transports.File level: 'debug', filename: 'logs/error.log'
	]

module.exports.middleware = (http) -> [
	
	(error, req, res, next) ->
		logger.error error.stack
		next error
			
	if 'development' isnt process.env.NODE_ENV
		(err, req, res, next) -> next err
	else
		express.errorHandler.title = 'Shrub'
		express.errorHandler()

]
