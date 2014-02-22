
express = require 'express'
nconf = require 'nconf'
winston = require 'winston'

logger = new winston.Logger
	transports: [
		new winston.transports.File level: 'debug', filename: 'logs/error.log'
	]

exports.$httpMiddleware = (http) ->
	
	label: 'Error handling'
	middleware: [
		
		if 'production' is nconf.get 'NODE_ENV'
			(err, req, res, next) -> next err
		else
			express.errorHandler.title = 'Shrub'
			express.errorHandler()
	
	]
