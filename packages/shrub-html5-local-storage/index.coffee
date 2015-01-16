
config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->
		
		gruntConfig.copy ?= {}
		
		gruntConfig.copy['shrub-html5-local-storage'] =
			files: [
				src: '**/*'
				dest: 'app'
				expand: true
				cwd: "#{__dirname}/app"
			]
		
		gruntConfig.shrub.tasks['build:shrub-html5-local-storage'] = [
			'newer:copy:shrub-html5-local-storage'
		]
		
		gruntConfig.shrub.tasks['build'].push 'build:shrub-html5-local-storage'

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
