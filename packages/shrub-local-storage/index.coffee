
config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->
		
		gruntConfig.clean ?= {}
		gruntConfig.copy ?= {}

		gruntConfig.clean['shrub-local-storage'] = [
			"app/lib/angular/angular-local-storage.js"
			"app/lib/angular/angular-local-storage.min.js"
		]

		gruntConfig.copy['shrub-local-storage'] =
			
			files: [
				cwd: "#{__dirname}/"
				expand: true
				src: [
					"angular-local-storage.js"
					"angular-local-storage.min.js"
				]
				dest: 'app/lib/angular/'
			]
			
		gruntConfig.shrub.tasks['build:shrub-local-storage'] = [
			'copy:shrub-local-storage'
		]
		
		gruntConfig.shrub.tasks['build'].push 'build:shrub-local-storage'
				
	# ## Implements hook `assetMiddleware`
	registrar.registerHook 'assetMiddleware', ->
		
		label: 'Angular HTML5 local storage'
		middleware: [
	
			(assets, next) ->
				
				if 'production' is config.get 'NODE_ENV'
					assets.scripts.push '/lib/angular/angular-local-storage.min.js'
				else
					assets.scripts.push '/lib/angular/angular-local-storage.js'
					
				next()
				
		]

	# ## Implements hook `angularCoreDependencies`
	registrar.registerHook 'angularCoreDependencies', -> [
		'LocalStorageModule'
	]
		
