
pkgman = require 'pkgman'

# Set up config.
config = (require 'config').config

# Register packages.
pkgman.registerPackages config.get 'packageList'

# Spin up!
pkgman.invoke 'genesis', (_, spec) -> spec config
