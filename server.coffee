
Promise = require 'bluebird'
winston = require 'winston'

errors = require 'errors'
pkgman = require 'pkgman'

# Set up config.
config = (require 'config').config

# Register packages.
pkgman.registerPackages config.get 'packageList'

# Initialize.
initializePromises = []
pkgman.invoke 'initialize', (_, spec) -> initializePromises.push spec config

# After initialization.
Promise.all(initializePromises).done(
	-> pkgman.invoke 'initialized', (_, spec) -> spec()
	(error) -> winston.error errors.message error
)
