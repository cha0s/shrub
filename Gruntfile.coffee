
module.exports = (grunt) ->
	
	config =
		pkg: grunt.file.readJSON 'package.json'
		
		shrub:
			
			tasks:
				'compile-clean': []
				'compile-coffee': []
				'compile-less': ['less']
				'compile': ['compile-coffee', 'compile-less', 'compile-clean']
				'default': ['compile']
				'production': ['compile', 'uglify']
		
		uglify: options: report: 'min'
	
	grunt.shrub =
		
		loadModule: (name) -> (require "./grunt/#{name}") grunt, config
			
		coffeeMapping: (coffees, output = 'build/js') ->
			grunt.file.expandMapping coffees, "#{output}/",
				rename: (destBase, destPath) ->
					destPath = destPath.replace /^client\//, ''
					destBase + destPath.replace /\.coffee$/, '.js'
		
	grunt.shrub.loadModule name for name in [
		'dependencies'
		'angular'
		'less'
		'modules'
		'shrub'
		'test'
	]
	
	grunt.initConfig config
	
	grunt.loadNpmTasks 'grunt-browserify'
	grunt.loadNpmTasks 'grunt-contrib-clean'
	grunt.loadNpmTasks 'grunt-contrib-coffee'
	grunt.loadNpmTasks 'grunt-contrib-concat'
	grunt.loadNpmTasks 'grunt-contrib-copy'
	grunt.loadNpmTasks 'grunt-contrib-less'
	grunt.loadNpmTasks 'grunt-contrib-uglify'
	grunt.loadNpmTasks 'grunt-contrib-watch'
	grunt.loadNpmTasks 'grunt-wrap'
	
	grunt.registerTask task, actions for task, actions of config.shrub.tasks
