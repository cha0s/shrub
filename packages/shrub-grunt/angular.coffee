
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->
		
		gruntConfig.clean ?= {}
		gruntConfig.coffee ?= {}
		gruntConfig.watch ?= {}
		
		gruntConfig.clean.angular = [
			'build/js/app.js'
		]
		
		gruntConfig.coffee.angular =
		
			files: [
				src: [
					'client/app.coffee'
				]
				dest: 'build/js/app.js'
			]
			expand: true
			ext: '.js'
		
		gruntConfig.watch.angular =

			files: [
				'client/app.coffee'
			]
			tasks: 'build:angular'
		
		gruntConfig.shrub.tasks['build:angular'] = [
			'coffee:angular'
		]
		
		gruntConfig.shrub.tasks['build'].push 'build:angular'
	