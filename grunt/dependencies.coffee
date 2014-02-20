
module.exports = (grunt, config) ->
	
	config.browserify ?= {}
	config.copy ?= {}
	
	config.browserify.inflection =
		files: 'build/js/dependencies/inflection.js': [
			'node_modules/inflection/lib/inflection.js'
		]
		options:
			standalone: 'inflection'

	config.browserify.jugglingdb =
		files: 'build/js/dependencies/jugglingdb-client.js': [
			'node_modules/jugglingdb/index.js'
		]
		options:
			standalone: 'jugglingdb'

	config.copy.inflection =
		expand: true
		cwd: 'build/js/dependencies'
		src: ['**/inflection.js']
		dest: 'client/modules'
	
	config.copy.jugglingdb =
		expand: true
		cwd: 'build/js/dependencies'
		src: ['**/jugglingdb-client.js']
		dest: 'client/modules'
	
	grunt.registerTask 'inflection', [
		'browserify:inflection'
		'copy:inflection'
	]

	grunt.registerTask 'jugglingdb', [
		'browserify:jugglingdb'
		'copy:jugglingdb'
	]

	grunt.registerTask 'dependencies', [
		'inflection'
		'jugglingdb'
	]
