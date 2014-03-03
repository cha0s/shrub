
module.exports = (grunt, config) ->
	
	config.browserify ?= {}
	config.copy ?= {}
	
	config.browserify.bluebird =
		files: 'build/js/dependencies/bluebird.js': [
			'node_modules/bluebird/js/main/bluebird.js'
		]
		options:
			standalone: 'inflection'

	config.browserify.inflection =
		files: 'build/js/dependencies/inflection.js': [
			'node_modules/inflection/lib/inflection.js'
		]
		options:
			standalone: 'inflection'

	config.browserify.jugglingdb =
		files: 'build/js/dependencies/jugglingdb-client.js': [
			'node_modules/promised-jugglingdb/index.js'
		]
		options:
			external: ['bluebird', 'inflection']
			detectGlobals: false
			standalone: 'jugglingdb'

	config.copy.bluebird =
		expand: true
		cwd: 'build/js/dependencies'
		src: ['**/bluebird.js']
		dest: 'client/modules'
	
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
	
	grunt.registerTask 'bluebird', [
		'browserify:bluebird'
		'copy:bluebird'
	]

	grunt.registerTask 'inflection', [
		'browserify:inflection'
		'copy:inflection'
	]

	grunt.registerTask 'jugglingdb', [
		'browserify:jugglingdb'
		'copy:jugglingdb'
	]

	grunt.registerTask 'dependencies', [
		'bluebird'
		'inflection'
		'jugglingdb'
	]
