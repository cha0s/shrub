
express = require 'express'
winston = require 'winston'

exports.$httpMiddleware = (http) ->
	
	label: 'Parse form submissions'
	middleware: [
		express.bodyParser()
		express.methodOverride()
	]
