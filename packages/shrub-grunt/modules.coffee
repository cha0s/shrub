
path = require 'path'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->

		{grunt} = gruntConfig

		gruntConfig.clean ?= {}
		gruntConfig.coffee ?= {}
		gruntConfig.concat ?= {}
		gruntConfig.copy ?= {}
		gruntConfig.watch ?= {}
		gruntConfig.wrap ?= {}

		gruntConfig.clean.modules = [
			'build/js/packages.js'
			'build/js/require.js'
			'build/js/modules'
			'build/js/custom'
			'build/js/packages'
			'build/js/modules.js'
		]

		gruntConfig.coffee.modules =

			files: [
				cwd: 'client'
				src: [
					'packages.coffee'
					'require.coffee'
					'modules/**/*.coffee'
				]
				dest: 'build/js'
				expand: true
				ext: '.js'
			,
				src: [
					'custom/*/client/**/*.coffee'
					'packages/*/client/**/*.coffee'
				]
				dest: 'build/js'
				expand: true
				ext: '.js'
			]

		gruntConfig.concat.modules =

			files: [
				src: [
					'build/js/modules.js'
					'build/js/packages.js'
					'build/js/require.js'
				]
				dest: 'build/js/modules.js'
			]

		gruntConfig.copy.modules =

			files: [
				expand: true
				cwd: 'client/modules'
				src: ['**/*.js']
				dest: 'build/js/modules'
			,
				expand: true
				src: ['packages/*/client/**/*.js']
				dest: 'build/js'
			,
				expand: true
				src: ['custom/*/client/**/*.js']
				dest: 'build/js'
			]

		gruntConfig.watch.modules =

			files: [
				'client/packages.coffee'
				'client/require.coffee'
				'client/modules/**/*.coffee'
				'custom/*/client/**/*.coffee'
				'packages/*/client/**/*.coffee'
			]
			tasks: [
				'build:modules', 'build:shrub'
			]
			options: livereload: true

		gruntConfig.wrap.modules =

			files: [
				src: [
					'build/js/modules/**/*.js'
					'build/js/custom/*/client/**/*.js'
					'build/js/packages/*/client/**/*.js'
				]
				dest: 'build/js/modules.js'
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

		gruntConfig.wrap.modulesAll =

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

		gruntConfig.shrub.tasks['build:modules'] = [
			'newer:coffee:modules'
			'newer:copy:modules'
			'wrap:modules'
			'concat:modules'
			'newer:wrap:modulesAll'
		]

		gruntConfig.shrub.tasks['build'].push 'build:modules'
