
module.exports = (grunt, config) ->

	lesses = [
		'app/less/**/*.less'
	]
	
	lessMapping = grunt.file.expandMapping lesses, 'app/css/',
		rename: (destBase, destPath) ->
			destPath = destPath.replace 'app/less/', ''
			destBase + destPath.replace /\.less$/, '.css'

	config.clean ?= {}
	config.less ?= {}
	config.watch ?= {}
	
	config.clean.less = lessMapping.map (file) -> file.dest
	
	config.less.compile =
		files: lessMapping
		
	config.watch.less =
		files: lesses
		tasks: 'compile-less'
	