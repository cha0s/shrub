
# # HTTP
# 
# Manage HTTP connections.

config = require 'config'

{defaultLogger} = require 'logging'

httpManager = null

# ## Implements hook `initialize`
exports.$initialize = ->
	
	{manager, port} = config.get 'packageSettings:http'
	
	{Manager} = require manager.module
	
	# Spin up the HTTP server, and initialize it.
	httpManager = new Manager()
	httpManager.initialize().then ->
	
		defaultLogger.info "Shrub HTTP server up and running on port #{port}!"
	
# ## Implements hook `packageSettings`
exports.$packageSettings = ->

	manager:
	
		# Module implementing the socket manager.
		module: 'packages/express'

	middleware: [
		'core'
		'socket/factory'
		'form'
		'session/express'
		'session'
		'user'
		'express/logger'
		'express/routes'
		'express/static'
		'config'
		'assets'
		'angular'
		'express/errors'
	]

	path: "#{config.get 'path'}/app"
	
	port: 4201
	
exports.manager = -> httpManager
