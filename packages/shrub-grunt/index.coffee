
config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `configAlter`
	registrar.registerHook 'configAlter', (req, config_) ->
		return unless req.grunt?

		config_.set 'packageConfig:shrub-socket', manager: module: 'shrub-socket/dummy'
		config_.set 'packageConfig:shrub-user', name: 'Anonymous'

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->

		{grunt} = gruntConfig

		gruntConfig.clean ?= {}
		gruntConfig.concat ?= {}
		gruntConfig.uglify ?= {}

		(gruntConfig.uglify.options ?= {}).report = 'min'

		gruntConfig.clean.shrub = [
			'app'
			'build'
		]

		gruntConfig.concat.shrub =

			files: [
				src: [
					'build/js/app/{app-bundled,modules}.js'
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

				grunt.fail.fatal 'Server process failed', code

		gruntConfig.shrub.tasks['build:shrub'] = [
			'concat:shrub'
		]

		gruntConfig.shrub.tasks['production:shrub'] = [
			'newer:uglify:shrub'
		]

		gruntConfig.shrub.tasks['execute'] = [
			'buildOnce'
			'executeFunction:shrub'
		]

		gruntConfig.shrub.npmTasks.push 'grunt-contrib-clean'
		gruntConfig.shrub.npmTasks.push 'grunt-contrib-coffee'
		gruntConfig.shrub.npmTasks.push 'grunt-contrib-concat'
		gruntConfig.shrub.npmTasks.push 'grunt-contrib-copy'
		gruntConfig.shrub.npmTasks.push 'grunt-contrib-uglify'
		gruntConfig.shrub.npmTasks.push 'grunt-contrib-watch'
		gruntConfig.shrub.npmTasks.push 'grunt-newer'
		gruntConfig.shrub.npmTasks.push 'grunt-wrap'

	# ## Implements hook `gruntConfigAlter`
	registrar.registerHook 'gruntConfigAlter', (gruntConfig) ->

		gruntConfig.shrub.tasks['build'].push 'build:shrub'
		gruntConfig.shrub.tasks['production'].push 'production:shrub'

	# ## Implements hook `skinRenderAppHtml`
	registrar.registerHook 'skinRenderAppHtml', ($) ->

		if 'production' isnt config.get 'NODE_ENV'

			$('body').append $('<script />').attr(
				src: 'http://localhost:35729/livereload.js'
			)

	registrar.recur [
		'angular', 'dox', 'lint', 'modules', 'tests'
	]
