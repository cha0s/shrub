
# # Logging
# 
# Provide a unified interface for logging information.

# ## .create
# 
# *Create a new logger instance.*
# 
# * (string) `type` - The type of log.
exports.create = (type) ->
	
	augmentedConsoleFunction = (key) -> ->
		args = (arg for arg in arguments)
		args.unshift type
		console[key].apply console, args
	
	# `TODO`: Bootstrapped, relies on proper client configuration.
	environment = ''
	
	# In production, we'll only log errors.
	if 'production' is environment
		
		debug: ->
		error: augmentedConsoleFunction 'error'
		info: ->
		log: ->
		warn: ->

	# Otherwise, we will show ALL the logs.
	else
		
		logger = {}
		logger[key] = augmentedConsoleFunction key for key in [
			'debug', 'error', 'info', 'log', 'warn'
		]
		logger
		
# Create a default logger, for convenience.
defaultLogger = exports.create 'shrub'
exports.defaultLogger = defaultLogger
