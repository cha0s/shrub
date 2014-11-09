
# # Server
# 
# The server application entry point. We load the configuration, invoke the
# initialization hooks, and listen for signals and process exit.

# First make sure we have default require paths.
if process.env.SHRUB_REQUIRE_PATH?

	SHRUB_REQUIRE_PATH = process.env.SHRUB_REQUIRE_PATH

else

	SHRUB_REQUIRE_PATH = 'custom:.:packages:server:client/modules'
		
# Fork the process to inject require paths into it.
unless process.env.SHRUB_FORKED?

	# Pass arguments to the child process.
	args = process.argv.slice 2
	
	# Pass the environment to the child process.
	options = env: process.env
	
	# Integrate any NODE_PATH after the shrub require paths.
	if process.env.NODE_PATH?
		SHRUB_REQUIRE_PATH += ":#{process.env.NODE_PATH}"
	
	# Inject shrub require paths as the new NODE_PATH
	options.env.NODE_PATH = SHRUB_REQUIRE_PATH
	options.env.SHRUB_FORKED = true
	
	# Fork it
	{fork} = require 'child_process'
	fork process.argv[1], args, options
	
# If it's already been forked, enter the application.
else
	
	Promise = require 'bluebird'
	
	debug = require('debug') 'shrub'
	errors = require 'errors'
	pkgman = require 'pkgman'
	schema = require('shrub-schema').schema()
	
	# } Load configuration.
	debug "Loading config..."
	
	config = require('config').load()
	
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
