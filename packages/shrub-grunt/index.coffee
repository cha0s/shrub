
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->
		
		gruntConfig.clean ?= {}
		gruntConfig.concat ?= {}
		gruntConfig.uglify ?= {}
		gruntConfig.watch ?= {}
		
		(gruntConfig.uglify.options ?= {}).report = 'min'
		
		gruntConfig.clean.shrub = [
			'app/lib/shrub/shrub.js'
			'app/lib/shrub/shrub.min.js'
		]
		
		gruntConfig.concat.shrub =

			files: [
				src: [
					'build/js/modules.js'
					'build/js/app.js'
				]
				dest: 'app/lib/shrub/shrub.js'
			]
		
		gruntConfig.uglify.shrub =
			
			files: [
				src: [
					'app/lib/shrub/shrub.js'
				]
				dest: 'app/lib/shrub/shrub.min.js'
			]
					
		gruntConfig.watch.shrub =

			files: [
				'build/js/modules.js'
				'build/js/app.js'
			]
			tasks: 'build:shrub'
		
		gruntConfig.shrub.tasks['executeFunction:shrub'] = ->
		
			done = @async()
			
			# Pass arguments to the child process.
			args = process.argv.slice 2
			
			# Pass the environment to the child process.
			options = env: process.env
			
			# Fork it
			{fork} = require 'child_process'
			child = fork "#{__dirname}/../../server.coffee", args, options
			
			child.on 'close', (code) ->
			
				return done() if code is 0
				
				gruntConfig.grunt.fail.fatal "Server process failed", code
			
		gruntConfig.shrub.tasks['build:shrub'] = [
			'concat:shrub'
		]
		
		gruntConfig.shrub.tasks['execute'] = [
			'buildOnce'
			'executeFunction:shrub'
		]

	# ## Implements hook `gruntConfigAlter`
	registrar.registerHook 'gruntConfigAlter', (gruntConfig) ->
		
		gruntConfig.shrub.tasks['build'].push 'build:shrub'
	
	registrar.recur [
		'angular', 'modules', 'tests'
	]
	