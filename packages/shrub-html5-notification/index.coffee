
config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->
		
		gruntConfig.copy ?= {}
		
		gruntConfig.copy['shrub-html5-notification'] =
			files: [
				src: '**/*'
				dest: 'app'
				expand: true
				cwd: "#{__dirname}/app"
			]
		
		gruntConfig.watch['shrub-html5-notification'] =

			files: [
				"#{__dirname}/app/**/*"
			]
			tasks: 'build:shrub-html5-notification'
		
		gruntConfig.shrub.tasks['build:shrub-html5-notification'] = [
			'newer:copy:shrub-html5-notification'
		]
		
		gruntConfig.shrub.tasks['build'].push 'build:shrub-html5-notification'

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
