
express = require 'express'

logging = require 'logging'

exports.$httpMiddleware = (http) ->
	
	clientRequestLogger = logging.create 'logs/express.client.log'
	serverRequestLogger = logging.create 'logs/express.server.log'
	
	label: 'Log requests'
	middleware: [

		express.logger stream:
			write: (message, encoding) ->
				
				logger = if message.match /(http:\/\/localhost:|node-XMLHttpRequest)/
					serverRequestLogger
				else
					clientRequestLogger
				
				logger.info message.slice 0, -1
				
	]
