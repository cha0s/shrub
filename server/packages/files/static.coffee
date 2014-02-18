
express = require 'express'

exports.$httpMiddleware = (http) ->
	
	label: 'Serve static files'
	middleware: [

		express.static http.path()
		
	]
