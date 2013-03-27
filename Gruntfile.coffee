
path = require 'path'

module.exports = (grunt) ->
	
	config =
		pkg: grunt.file.readJSON 'package.json'
		
		shrub: 
			tasks:
				'compile-coffee': []
				'compile-less': ['less']
				'compile': ['compile-coffee', 'compile-less']
				'default': ['compile']
				'production': ['compile', 'uglify']
		
		uglify: options: report: 'min'
	
	grunt.shrub =
		loadModule: (name) ->
			(require path.join __dirname, 'grunt', name) grunt, config
	
	grunt.shrub.loadModule name for name in [
		'angular', 'less', 'modules', 'test'
	]
	
	grunt.initConfig config
	
	grunt.loadNpmTasks 'grunt-contrib-clean'
	grunt.loadNpmTasks 'grunt-contrib-coffee'
	grunt.loadNpmTasks 'grunt-contrib-concat'
	grunt.loadNpmTasks 'grunt-contrib-less'
	grunt.loadNpmTasks 'grunt-contrib-uglify'
	grunt.loadNpmTasks 'grunt-contrib-watch'
	grunt.loadNpmTasks 'grunt-wrap'
	
	grunt.registerTask task, actions for task, actions of config.shrub.tasks
