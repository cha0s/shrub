
# # Server
# 
# The server application entry point. We load the configuration, invoke the
# initialization hooks, and listen for signals and process exit.

Promise = require 'bluebird'

errors = require 'errors'
pkgman = require 'pkgman'

{defaultLogger} = require 'logging'

# } Set up config.
config = require('config').load()

Promise.all(
	
	# Invoke hook `initialize`.
	# Invoked when the server is just starting. Implementations should return
	# a promise. When all returned promises are fulfilled, initialization
	# continues.
	pkgman.invokeFlat 'initialize', config

# } After initialization.
).done(

	# Invoke hook `initialized`.
	# Invoked after the server is initialized.
	# 
	# `TODO`: Rename to `ready`.
	-> pkgman.invoke 'initialized'
	(error) ->
		
		defaultLogger.error errors.stack error
		
		# } Rethrow any error.
		throw error
)

# Do our best to guarantee that hook `processExit` will always be invoked.

# } Signal listeners and process cleanup.
process.on 'SIGINT', -> process.exit()
process.on 'SIGTERM', -> process.exit()

process.on 'exit', -> pkgman.invoke 'processExit'
