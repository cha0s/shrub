
# # Express static files

express = require 'express'

config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `httpMiddleware`
	#
	# Serve static files.
	registrar.registerHook 'httpMiddleware', (http) ->

		label: 'Serve static files'
		middleware: [
			express.static config.get 'packageSettings:shrub-http:path'
		]
