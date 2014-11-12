
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->
		
		gruntConfig.clean ?= {}
		gruntConfig.concat ?= {}
		gruntConfig.uglify ?= {}
		gruntConfig.watch ?= {}
		
		(gruntConfig.uglify.options ?= {}).report = 'min'
		
		gruntConfig.clean.shrub = [
			'app/shrub.js'
			'app/shrub.min.js'
		]
		
		gruntConfig.concat.shrub =

			files: [
				src: [
					'build/js/modules.js'
					'build/js/app.js'
				]
				dest: 'app/shrub.js'
			]
		
		gruntConfig.uglify.shrub =
			
			files: [
				src: [
					'app/shrub.js'
				]
				dest: 'app/shrub.min.js'
			]
					
		gruntConfig.watch.shrub =

			files: [
				'build/js/modules.js'
				'build/js/app.js'
			]
			tasks: 'build:shrub'
			
		gruntConfig.shrub.tasks['build:shrub'] = [
			'concat:shrub'
		]
		
	# ## Implements hook `gruntConfigAlter`
	registrar.registerHook 'gruntConfigAlter', (gruntConfig) ->
		
		gruntConfig.shrub.tasks['build'].push 'build:shrub'
	
	registrar.recur [
		'angular', 'modules', 'tests'
	]
	