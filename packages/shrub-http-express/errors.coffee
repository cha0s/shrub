
# # Express error handler

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `httpMiddleware`
	registrar.registerHook 'httpMiddleware', (http) ->

		express = require 'express'
		config = require 'config'

		errors = require 'errors'
		logging = require 'logging'

		logger = logging.create 'logs/error.log'

		label: 'Error handling'
		middleware: [

			# In production, we'll just log the error and continue.
			if 'production' is config.get 'NODE_ENV'

				(error, req, res, next) ->

					logger.error errors.stack error
					next error

			# Otherwise, we'll let Express format the error all pretty-like.
			else

				express.errorHandler.title = 'Shrub'
				express.errorHandler()

		]
