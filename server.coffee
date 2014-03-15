
Promise = require 'bluebird'
winston = require 'winston'

errors = require 'errors'
pkgman = require 'pkgman'

# Set up config.
config = (require 'config').config

# Register packages.
pkgman.registerPackages config.get 'packageList'

# Initialize.
initializePromises = for _, promise of pkgman.invoke 'initialize', config
	promise

# After initialization.
Promise.all(initializePromises).done(
	-> pkgman.invoke 'initialized'
	(error) -> winston.error errors.stack error
)
