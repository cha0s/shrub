
express = require 'express'
nconf = require 'nconf'

errors = require 'errors'
logging = require 'logging'

exports.$httpMiddleware = (http) ->
	
	logger = logging.create 'logs/error.log'

	label: 'Error handling'
	middleware: [
		
		if 'production' is nconf.get 'NODE_ENV'
			
			(error, req, res, next) ->
		
				logger.error errors.stack error
				next error
		
		else
		
			express.errorHandler.title = 'Shrub'
			express.errorHandler()
	
	]
