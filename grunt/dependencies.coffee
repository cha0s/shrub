
module.exports = (grunt, config) ->
	
	config.browserify ?= {}
	config.copy ?= {}
	
	config.browserify.jugglingdb =
		files: 'build/js/dependencies/jugglingdb-client.js': [
			'node_modules/jugglingdb/index.js'
		]
		options:
			standalone: 'jugglingdb'

	config.copy.jugglingdb =
		expand: true
		cwd: 'build/js/dependencies'
		src: ['**/jugglingdb-client.js']
		dest: 'client/modules'
	
	grunt.registerTask 'jugglingdb', [
		'browserify:jugglingdb'
		'copy:jugglingdb'
	]

	grunt.registerTask 'dependencies', [
		'jugglingdb'
	]
