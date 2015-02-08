
# # Server
#
# The server application entry point. We load the configuration, invoke the
# initialization hooks, and listen for signals and process exit.

# Fully qualified because before bootstrap we don't have good require paths.
{fork} = require "#{__dirname}/server/bootstrap"

# Fork the process to inject require paths into it.
unless fork()

	Promise = require 'bluebird'

	debug = require('debug') 'shrub:server'
	errors = require 'errors'

	middleware = require 'middleware'
	pkgman = require 'pkgman'

	# } Load configuration.
	debug 'Loading config...'

	config = require 'config'
	config.load()
	config.loadPackageSettings()

	debug 'Config loaded.'

	debug 'Pre bootstrap phase...'
	pkgman.invoke 'preBootstrap'
	debug 'Pre bootstrap phase completed.'

	debug 'Loading bootstrap middleware...'
	bootstrapMiddleware = middleware.fromHook(
		'bootstrapMiddleware'
		config.get 'packageSettings:shrub-core:bootstrapMiddleware'
	)
	debug 'Bootstrap middleware loaded.'

	bootstrapMiddleware.dispatch (error) ->

		# Invoke hook `ready`.
		# Invoked after the server is initialized and ready.
		# `TODO`: Remove this; implementations should use
		# `bootstrapMiddleware`.
		return pkgman.invoke 'ready' unless error?

		console.error errors.stack error
		throw error

	# Do our best to guarantee that hook `processExit` will always be invoked.

	# } Signal listeners and process cleanup.
	process.on 'SIGINT', -> process.exit()
	process.on 'SIGTERM', -> process.exit()

	process.on 'exit', -> pkgman.invoke 'processExit'
