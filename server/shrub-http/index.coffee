
# # HTTP
# 
# Manage HTTP connections.

config = require 'config'

{defaultLogger} = require 'logging'

httpManager = null

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `initialize`
	registrar.registerHook 'initialize', ->
		
		{manager, port} = config.get 'packageSettings:shrub-http'
		
		Manager = require manager.module
		
		# Spin up the HTTP server, and initialize it.
		httpManager = new Manager()
		httpManager.initialize().then ->
		
			defaultLogger.info "Shrub HTTP server up and running on port #{port}!"
		
	# ## Implements hook `packageSettings`
	registrar.registerHook 'packageSettings', ->
		
		manager:
		
			# Module implementing the socket manager.
			module: 'shrub-express'
	
		middleware: [
			'shrub-core'
			'shrub-socket/factory'
			'shrub-form'
			'shrub-session/express'
			'shrub-session'
			'shrub-user'
			'shrub-express/logger'
			'shrub-express/routes'
			'shrub-express/static'
			'shrub-config'
			'shrub-assets'
			'shrub-angular'
			'shrub-express/errors'
		]
	
		path: "#{config.get 'path'}/app"
		
		port: 4201
	
exports.manager = -> httpManager
