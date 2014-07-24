
# # Assets
# 
# Serve different JS based on whether the server is running in production mode.

_ = require 'underscore'
config = require 'config'
middleware = require 'middleware'
pkgman = require 'pkgman'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `assetScriptMiddleware`
	registrar.registerHook 'assetScriptMiddleware', ->
		
		label: 'Shrub'
		middleware: [
	
			(req, res, next) ->
				
				if 'production' is config.get 'NODE_ENV'
					
					res.locals.scripts.push '/shrub.min.js'
					
				else
					
					res.locals.scripts.push '/shrub.js'
					
				next()
				
		]

	# ## Implements hook `httpMiddleware`
	registrar.registerHook 'httpMiddleware', (http) ->
		
		# Invoke hook `assetScriptMiddleware`.
		# Invoked to gather script assets for requests.
		scriptMiddleware = middleware.fromShortName(
			'asset script'
			'shrub-assets'
		)
		
		label: 'Serve dynamic assets'
		middleware: [
	
			(req, res, next) ->
				
				res.locals ?= {}
				res.locals.scripts ?= []
				
				# Gather script asset list.
				scriptMiddleware.dispatch req, res, next
				
		]

	# ## Implements hook `packageSettings`
	registrar.registerHook 'packageSettings', ->
		
		scriptMiddleware: [
			'shrub-assets/jquery'
			'shrub-assets/bootstrap'
			'shrub-socket.io'
			'shrub-assets/angular'
			'shrub-assets/ui-bootstrap'
			'shrub-assets'
			'shrub-config'
		]
		
	registrar.recur [
		'angular', 'bootstrap', 'jquery', 'ui-bootstrap'
	]
