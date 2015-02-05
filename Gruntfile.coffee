
{fork} = require "#{__dirname}/server/bootstrap"

module.exports = (grunt) ->

	# Fork so we can bootstrap a Shrub environment.
	if child = fork()
		grunt.registerTask 'bootstrap', ->

			done = @async()

			child.on 'close', (code) ->

				return done() if code is 0

				grunt.fail.fatal 'Child process failed', code

		# Forward all tasks.
		{tasks} = require 'grunt/lib/grunt/cli'
		grunt.registerTask tasks[0] ? 'default', ['bootstrap']
		grunt.registerTask(task, (->)) for task in tasks.slice 1

		return

	# } Load configuration.
	config = require 'config'
	pkgman = require 'pkgman'

	config.load()
	config.loadPackageSettings()

	# Load grunt configuration.
	gruntConfig =

		grunt: grunt

		pkg: grunt.file.readJSON 'package.json'

		shrub:

			npmTasks: []

			tasks:
				build: []
				production: [
					'build'
				]
				default: [
					'buildOnce'
				]

	built = false

	gruntConfig.shrub.tasks['buildOnce'] = ->
		return if built
		built = true

		grunt.task.run 'build'

	pkgman.invoke 'gruntConfig', gruntConfig
	pkgman.invoke 'gruntConfigAlter', gruntConfig

	grunt.initConfig gruntConfig

	# Load NPM tasks.
	npmTasksLoaded = {}
	for task in gruntConfig.shrub.npmTasks
		continue if npmTasksLoaded[task]?
		npmTasksLoaded[task] = true
		grunt.loadNpmTasks task

	# Register custom tasks.
	for task, actions of gruntConfig.shrub.tasks
		grunt.registerTask task, actions
