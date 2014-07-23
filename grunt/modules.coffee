path = require 'path'

module.exports = (grunt, config) ->

	moduleCoffees = [
		'client/packages.coffee'
		'client/require.coffee'
		'client/modules/**/*.coffee'
		'custom/*/client/**/*.coffee'
		
		'!client/modules/**/test-e2e.coffee'
		'!client/modules/**/test-unit.coffee'
		'!client/modules/**/*.spec.coffee'
	
		'packages/*/client/**/*.coffee'
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
	
		files: [
			cwd: 'client'
			src: [
				'packages.coffee'
				'require.coffee'

				'modules/**/*.coffee'
				'!modules/**/test-e2e.coffee'
				'!modules/**/test-unit.coffee'
				'!modules/**/*.spec.coffee'
			]
			dest: 'build/js'
			expand: true
			ext: '.js'
		,
			src: [
				'custom/*/client/**/*.coffee'
				'!custom/*/client/**/test-e2e.coffee'
				'!custom/*/client/**/test-unit.coffee'
				'!custom/*/client/**/*.spec.coffee'

				'packages/*/client/**/*.coffee'
				'!packages/*/client/**/test-e2e.coffee'
				'!packages/*/client/**/test-unit.coffee'
				'!packages/*/client/**/*.spec.coffee'
			]
			dest: 'build/js'
			expand: true
			ext: '.js'
		]
	
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
				'build/js/packages/*/client/**/*.js'
			]
		options:
			indent: '  '
			wrapper: (filepath) ->
				
				matches = filepath.match /build\/js\/([^/]+)\/(.*)/
				
				switch matches[1]
					
					when 'modules'
						
						moduleName = matches[2]
					
					when 'custom', 'packages'

						parts = matches[2].split '/'
						parts.splice 1, 1
						moduleName = parts.join '/'
				
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
	
#	config.shrub.tasks['compile-clean'].push 'clean:modulesBuild'
	
	config.shrub.tasks['compile-coffee'].push 'compile-modules'
	