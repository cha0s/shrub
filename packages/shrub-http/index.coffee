
# # HTTP
# 
# Manage HTTP connections.

config = require 'config'
debug = require('debug') 'shrub:http'

httpManager = null

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `initialize`
	registrar.registerHook 'initialize', ->
		
		{manager, port} = config.get 'packageSettings:shrub-http'
		
		{Manager} = require manager.module
		
		# Spin up the HTTP server, and initialize it.
		httpManager = new Manager()
		httpManager.initialize().then ->
		
			debug "Shrub HTTP server up and running on port #{port}!"
		
	# ## Implements hook `packageSettings`
	registrar.registerHook 'packageSettings', ->
		
		manager:
		
			# Module implementing the socket manager.
			module: 'shrub-http-express'
	
		middleware: [
			'shrub-core'
			'shrub-socket/factory'
			'shrub-form'
			'shrub-http-express/session'
			'shrub-user'
			'shrub-http-express/logger'
			'shrub-http-express/routes'
			'shrub-http-express/static'
			'shrub-config'
			'shrub-skin'
			'shrub-assets'
			'shrub-angular'
			'shrub-http-express/errors'
		]
	
		path: "#{config.get 'path'}/app"
		
		port: 4201
	
exports.manager = -> httpManager
