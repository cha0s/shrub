path = require 'path'

module.exports = (grunt, config) ->

	moduleCoffees = [
		'client/packages.coffee'
		'client/require.coffee'
		'client/modules/**/*.coffee'
	]
	moduleCoffeeMapping = grunt.file.expandMapping moduleCoffees, 'build/js/',
		rename: (destBase, destPath) ->
			destPath = destPath.replace 'client/', ''
			destBase + destPath.replace /\.coffee$/, '.js'
	
	config.clean ?= {}
	config.coffee ?= {}
	config.concat ?= {}
	config.copy ?= {}
	config.uglify ?= {}
	config.watch ?= {}
	config.wrap ?= {}
	
	config.clean.modules = [
		'build/js/modules.js'
		'build/js/modules.min.js'
	]
	
	config.clean.modulesBuild = [
		'build/js/modules/**/*.js'
	]
	
	config.coffee.modules =
		files: moduleCoffeeMapping
	
	config.concat.modules =
		src: [
			'build/js/modules.js'
			'build/js/packages.js'
			'build/js/require.js'
		]
		dest: 'build/js/modules.js'
	
	config.copy.modules =
		expand: true
		cwd: 'client/modules'
		src: ['**/*.js']
		dest: 'build/js/modules'
	
	config.uglify.modules =
		files: 'build/js/modules.min.js': ['build/js/modules.js']
	
	config.watch.modules =
		files: moduleCoffees.concat [
			'client/modules/**/*.js'
			
			'!client/modules/**/test-e2e.coffee'
			'!client/modules/**/test-unit.coffee'
		]
		tasks: 'compile-modules'
	
	config.wrap.modules =
		files:
			'build/js/modules.js': [
				'build/js/modules/**/*.js'
			]
		options:
			indent: '  '
			wrapper: (filepath) ->
				
				moduleName = filepath.substr 'build/js/modules/'.length
				
				dirname = path.dirname moduleName
				extname = path.extname moduleName
				moduleName = path.join dirname, path.basename moduleName, extname 
				
				if moduleName?
					["requires_['#{moduleName}'] = function(module, exports, require) {\n\n", '\n};\n']
				else
					['', '']
	
	config.wrap.modulesAll =
		files: ['build/js/modules.js'].map (file) -> src: file, dest: file
		options:
			indent: '  '
			wrapper: [
				"""
(function() {

  var requires_ = {};


"""
				"""

})();

"""
			]

	grunt.registerTask 'compile-modules', [
		'coffee:modules'
		'copy:modules'
		'wrap:modules'
		'concat:modules'
		'wrap:modulesAll'
		'clean:modulesBuild'
	]
	
	config.shrub.tasks['compile-coffee'].push 'compile-modules'
	