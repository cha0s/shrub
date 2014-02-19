
module.exports = (grunt, config) ->
	
	config.clean ?= {}
	config.concat ?= {}
	config.uglify ?= {}
	config.watch ?= {}
	
	config.clean.shrub = [
		'app/shrub.js'
		'app/shrub.min.js'
	]
	
	config.concat.shrub =
		src: [
			'build/js/modules.js'
			'build/js/app.js'
		]
		dest: 'app/shrub.js'
	
	config.uglify.shrub =
		files:
			'app/shrub.min.js': [
				'app/shrub.js'
			]
				
	config.watch.shrub =
		files: [
			'build/js/modules.js'
			'build/js/app.js'
		]
		tasks: 'compile-shrub'
		
	grunt.registerTask 'compile-shrub', [
		'concat:shrub'
	]
	
	config.shrub.tasks['compile-coffee'].push 'compile-shrub'
	