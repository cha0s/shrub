path = require 'path'

module.exports = (grunt, config) ->

	moduleCoffees = [
		'app/coffee/modules/**/*.coffee'
	]
	moduleCoffeeMapping = grunt.file.expandMapping moduleCoffees, 'app/js/',
		rename: (destBase, destPath) ->
			destPath = destPath.replace 'app/coffee/', ''
			destBase + destPath.replace /\.coffee$/, '.js'
	
	config.clean ?= {}
	config.coffee ?= {}
	config.concat ?= {}
	config.uglify ?= {}
	config.watch ?= {}
	config.wrap ?= {}
	
	config.clean.modules = [
		'app/js/modules.js'
		'app/js/modules.min.js'
	]
	
	config.clean.modulesBuild = moduleCoffeeMapping.map (file) -> file.dest
	
	config.coffee.modules =
		files: moduleCoffeeMapping
	
	config.concat.modules =
		src: [
			'app/js/modules/require.js'
			'app/js/modules.js'
		]
		dest: 'app/js/modules.js'
	
	config.uglify.modules =
		files: 'app/js/modules.min.js': ['app/js/modules.js']
	
	config.watch.modules =
		files: moduleCoffees
		tasks: 'compile-modules'
	
	config.wrap.modules =
		files:
			'app/js/modules.js': [
				'app/js/modules/**/*.js'
				'!app/js/modules/require.js'
			]
		options:
			indent: '  '
			wrapper: (filepath) ->
				
				moduleName = filepath.substr 15
				
				dirname = path.dirname moduleName
				extname = path.extname moduleName
				moduleName = path.join dirname, path.basename moduleName, extname 
				
				if moduleName?
					["requires_['#{moduleName}'] = function(module, exports, require) {\n\n", '\n};\n']
				else
					['', '']
	
	config.wrap.modulesAll =
		files: ['app/js/modules.js'].map (file) -> src: file, dest: file
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
		'wrap:modules'
		'concat:modules'
		'wrap:modulesAll'
		'clean:modulesBuild'
	]
	
	config.shrub.tasks['compile-coffee'].push 'compile-modules'
	