
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->
		
		gruntConfig.copy ?= {}
		
		gruntConfig.copy['shrub-example'] =
			files: [
				src: 'README.md'
				dest: 'app/shrub-example/about/README.md'
			]
		
		gruntConfig.shrub.tasks['build:shrub-example'] = [
			'newer:copy:shrub-example'
		]
		
		gruntConfig.shrub.tasks['build'].push 'build:shrub-example'
