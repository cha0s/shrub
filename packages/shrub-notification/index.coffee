
config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->
		
		gruntConfig.clean ?= {}
		gruntConfig.copy ?= {}

		gruntConfig.clean['shrub-notification'] = [
			"app/lib/angular/angular-notification.js"
			"app/lib/angular/angular-notification.min.js"
		]

		gruntConfig.copy['shrub-notification'] =
			
			files: [
				cwd: "#{__dirname}/"
				expand: true
				src: [
					"angular-notification.js"
					"angular-notification.min.js"
				]
				dest: 'app/lib/angular/'
			]
			
		gruntConfig.shrub.tasks['build:shrub-notification'] = [
			'copy:shrub-notification'
		]
		
		gruntConfig.shrub.tasks['build'].push 'build:shrub-notification'
				
	# ## Implements hook `assetMiddleware`
	registrar.registerHook 'assetMiddleware', ->
		
		label: 'Angular HTML5 notifications'
		middleware: [
	
			(assets, next) ->
				
				if 'production' is config.get 'NODE_ENV'
					assets.scripts.push '/lib/angular/angular-notification.min.js'
				else
					assets.scripts.push '/lib/angular/angular-notification.js'
					
				next()
				
		]

	# ## Implements hook `angularCoreDependencies`
	registrar.registerHook 'angularCoreDependencies', -> [
		'notification'
	]
		
