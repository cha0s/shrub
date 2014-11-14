
{fork} = require './environment'

module.exports = (grunt) ->
	
	# Fork so we can have a Shrub environment.
	if child = fork()
		grunt.registerTask 'shrub-environment', -> child.on 'close', this.async()
		
		# Forward all tasks.
		{tasks} = require 'grunt/lib/grunt/cli'
		grunt.registerTask tasks[0] ? 'default', ['shrub-environment']
		grunt.registerTask(task, ->) for task in tasks.slice 1
			
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
				'build': []
				'default': ['build']
		
		uglify: options: report: 'min'
		
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
