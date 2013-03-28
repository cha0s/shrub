
express = require 'express'
path = require 'path'

module.exports = new class
	
	middleware: (app) ->
		
		appDirectory = path.join __dirname, '..', 'app'
		
		app.use express.favicon path.join appDirectory, 'favicon.ico'
	
		app.use express.bodyParser()
		app.use express.methodOverride()
		
		app.use app.router
		app.use express.static appDirectory
	
	route: (app) ->

		routesDirectory = path.join __dirname, 'routes'
		for route in [
			'index'
		]
			require(path.join routesDirectory, route) app
