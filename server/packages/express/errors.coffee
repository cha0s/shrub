
# # Express error handler

express = require 'express'
nconf = require 'nconf'

errors = require 'errors'
logging = require 'logging'

# ## Implements hook `httpMiddleware`
exports.$httpMiddleware = (http) ->
	
	logger = logging.create 'logs/error.log'

	label: 'Error handling'
	middleware: [
		
		# In production, we'll just log the error and continue.
		if 'production' is nconf.get 'NODE_ENV'
			
			(error, req, res, next) ->
		
				logger.error errors.stack error
				next error
		
		# Otherwise, we'll let Express format the error all pretty-like.
		else
		
			express.errorHandler.title = 'Shrub'
			express.errorHandler()
	
	]
