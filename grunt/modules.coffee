path = require 'path'

module.exports = (grunt, config) ->

	moduleCoffeeMapping = grunt.shrub.coffeeMapping moduleCoffees = [
		'client/packages.coffee'
		'client/require.coffee'
		'client/modules/**/*.coffee'
		'custom/*/client/**/*.coffee'
		
		'!client/modules/**/test-e2e.coffee'
		'!client/modules/**/test-unit.coffee'
		'!client/modules/**/*.spec.coffee'
	]
	
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
		'build/js/packages.js'
		'build/js/require.js'
		'build/js/modules'
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
		
		files: [
			expand: true
			cwd: 'client/modules'
			src: ['**/*.js']
			dest: 'build/js/modules'
		,
			expand: true
			cwd: 'custom'
			src: ['*/client/**/*.js']
			dest: 'build/js/modules'
		]
	
	config.uglify.modules =
		files: 'build/js/modules.min.js': ['build/js/modules.js']
	
	config.watch.modules =
		files: moduleCoffees.concat [
			'client/modules/**/*.js'
			
			'!client/modules/**/test-e2e.coffee'
			'!client/modules/**/test-unit.coffee'
		]
		tasks: ['compile-modules', 'clean:modulesBuild']
	
	config.wrap.modules =
		files:
			'build/js/modules.js': [
				'build/js/modules/**/*.js'
				'build/js/custom/*/client/**/*.js'
			]
		options:
			indent: '  '
			wrapper: (filepath) ->
				
				matches = filepath.match /build\/js\/[^/]+\/(.*)/
				
				if filepath.match /^build\/js\/custom\//
					parts = matches[1].split '/'
					parts.splice 1, 1
					moduleName = parts.join '/'
				else
					moduleName = matches[1]

				dirname = path.dirname moduleName
				if dirname is '.' then dirname = '' else dirname += '/'
				
				extname = path.extname moduleName
				moduleName = "#{dirname}#{path.basename moduleName, extname}"
				
				if moduleName?
					[
						"""
requires_['#{moduleName}'] = function(module, exports, require, __dirname, __filename) {


"""
						"""

};

"""
					]
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
	]
	
	config.shrub.tasks['compile-clean'].push 'clean:modulesBuild'
	
	config.shrub.tasks['compile-coffee'].push 'compile-modules'
	