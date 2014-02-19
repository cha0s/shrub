
# Set up config.
config = require 'config'

# Register packages.
(require 'pkgman').registerPackages config.get 'packageList'

# Spin up the HTTP server and go!
Http = require "packages/#{config.get 'services:http:package'}"
http = new Http config.get 'services:http'
http.initialize (error) ->
	return (require 'winston').error error.stack if error?
	
	console.info "Shrub server up and running!"
