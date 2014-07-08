
# # Express static files

express = require 'express'

config = require 'config'

# ## Implements hook `httpMiddleware`
# 
# Serve static files.
exports.$httpMiddleware = (http) ->
	
	label: 'Serve static files'
	middleware: [
		express.static config.get 'packageSettings:shrub-http:path'
	]
