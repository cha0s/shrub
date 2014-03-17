
Promise = require 'bluebird'
winston = require 'winston'

errors = require 'errors'
pkgman = require 'pkgman'

# Set up config.
config = require 'config'
config.loadSettings()

# Initialize.
initializers = pkgman.invoke 'initialize', config.loadPackageSettings()
initializePromises = (promise for _, promise of initializers)

# After initialization.
Promise.all(initializePromises).done(
	-> pkgman.invoke 'initialized'
	(error) -> winston.error errors.stack error
)

# Signal listeners and process cleanup.

process.on 'SIGINT', -> process.exit()
process.on 'SIGTERM', -> process.exit()

process.on 'exit', -> pkgman.invoke 'processExit'
