
fs = require 'fs'
path = require 'path'

module.exports = new class
	
	initialize: (app) ->
	
# Read the settings file. Configuration variables will be accessible at
# app.get/set
		filename = path.join __dirname, '..', 'config', 'settings.json'
		if fs.existsSync filename
			settings = fs.readFileSync filename
		else
			throw new Error "Copy config/settings-default.json to config/settings.json"
		app.set key, value for key, value of JSON.parse settings.toString()
	
	middleware: (app) ->

		app.use (req, res, next) ->
			
			app = req.app
			
			req.config =
			
				debugging: 'production' isnt app.get 'env'
			
			next()
			