
express = require 'express'
winston = require 'winston'

clientRequestLogger = new winston.Logger
	transports: [
		new winston.transports.Console level: 'error', colorize: true
		new winston.transports.File level: 'debug', filename: 'logs/express.client.log'
	]

serverRequestLogger = new winston.Logger
	transports: [
		new winston.transports.Console level: 'error', colorize: true
		new winston.transports.File level: 'debug', filename: 'logs/express.server.log'
	]

module.exports.middleware = (http) ->
	
	express.logger stream:
		write: (message, encoding) ->
			
			logger = if message.match /(http:\/\/localhost:|node-XMLHttpRequest)/
				serverRequestLogger
			else
				clientRequestLogger
			
			logger.info message.slice 0, -1
