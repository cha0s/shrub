
# # Express static files

express = require 'express'

# ## Implements hook `httpMiddleware`
# 
# Serve static files.
exports.$httpMiddleware = (http) ->
	
	label: 'Serve static files'
	middleware: [

		express.static http.path()
		
	]
