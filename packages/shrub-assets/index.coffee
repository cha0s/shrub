
# # Assets
# 
# Serve different JS based on whether the server is running in production mode.

_ = require 'underscore'
config = require 'config'
middleware = require 'middleware'
pkgman = require 'pkgman'

assets = null

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `clearCaches`
	registrar.registerHook 'clearCaches', ->
		
		assets = null
	
	# ## Implements hook `assetMiddleware`
	registrar.registerHook 'assetMiddleware', ->
		
		label: 'Shrub'
		middleware: [
	
			(assets, next) ->
				
				if 'production' is config.get 'NODE_ENV'
					assets.scripts.push '/lib/shrub/shrub.min.js'
				else
					assets.scripts.push '/lib/shrub/shrub.js'
					
				assets.styleSheets.push '/css/shrub.css'
				
				next()
				
		]

	# ## Implements hook `packageSettings`
	registrar.registerHook 'packageSettings', ->
		
		assetMiddleware: [
			'shrub-assets/jquery'
			'shrub-socket-socket.io'
			'shrub-assets/angular'
			'shrub-assets'
			'shrub-config'
		]
		
	registrar.recur [
		'angular', 'bootstrap', 'jquery', 'ui-bootstrap'
	]
	
exports.assets = ->
	return assets if assets?
	
	assets = scripts: [], styleSheets: []

	# Invoke hook `assetMiddleware`.
	# Invoked to gather script assets for requests.
	assetMiddleware = middleware.fromHook(
		'assetMiddleware'
		config.get "packageSettings:shrub-assets:assetMiddleware"
	)
	
	assetMiddleware.dispatch assets, (error) -> throw error if error?
	
	assets
	