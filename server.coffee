
# # Server
# 
# The server application entry point. We load the configuration, invoke the
# initialization hooks, and listen for signals and process exit.

{fork} = require './environment'

# Fork the process to inject require paths into it.
unless fork()

	Promise = require 'bluebird'
	
	debug = require('debug') 'shrub'
	errors = require 'errors'
	pkgman = require 'pkgman'
	schema = require('shrub-schema').schema()
	
	# } Load configuration.
	debug "Loading config..."
	
	config = require 'config'
	config.load()
	config.loadPackageSettings()
	
	debug "Config loaded."
	
	# } Let packages define their models in the schema.
	schema.definePackageModels()
	
	Promise.all(
		
		# Invoke hook `initialize`.
		# Invoked when the server is just starting. Implementations should
		# return a promise. When all returned promises are fulfilled,
		# initialization continues.
		pkgman.invokeFlat 'initialize'
	
	# } After initialization.
	).done(
	
		# Invoke hook `ready`.
		# Invoked after the server is initialized and ready.
		-> pkgman.invoke 'ready'
		(error) ->
			
			console.error errors.stack error
			
			# } Rethrow any error.
			throw error
	)
	
	# Do our best to guarantee that hook `processExit` will always be invoked.
	
	# } Signal listeners and process cleanup.
	process.on 'SIGINT', -> process.exit()
	process.on 'SIGTERM', -> process.exit()
	
	process.on 'exit', -> pkgman.invoke 'processExit'
