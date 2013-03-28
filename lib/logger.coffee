
express = require 'express'
fs = require 'fs'
path = require 'path'

module.exports = new class
	
	middleware: (app) ->
	
# Log to logs/express.

		app.use express.logger stream: fs.createWriteStream(
			path.join 'logs', 'express'
			flags: 'a'
		)
