
module.exports = (grunt, config) ->
	
	config.browserify ?= {}
	config.copy ?= {}
	
	config.browserify.bluebird =
		files: 'build/js/dependencies/bluebird.js': [
			'node_modules/bluebird/js/main/bluebird.js'
		]
		options:
			detectGlobals: false
			standalone: 'bluebird'

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
			external: ['bluebird', 'inflection', 'path']
			standalone: 'jugglingdb'

	config.browserify.path =
		files: 'build/js/dependencies/path.js': [
			'node_modules/browserify/node_modules/path-browserify/index.js'
		]
		options:
			standalone: 'path'
	
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
	
	config.copy.path =
		expand: true
		cwd: 'build/js/dependencies'
		src: ['**/path.js']
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

	grunt.registerTask 'path', [
		'browserify:path'
		'copy:path'
	]

	grunt.registerTask 'dependencies', [
		'bluebird'
		'inflection'
		'jugglingdb'
		'path'
	]
