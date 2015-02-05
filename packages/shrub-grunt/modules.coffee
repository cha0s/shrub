
path = require 'path'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->

		{grunt} = gruntConfig

		gruntConfig.coffee ?= {}
		gruntConfig.concat ?= {}
		gruntConfig.copy ?= {}
		gruntConfig.watch ?= {}
		gruntConfig.wrap ?= {}

		gruntConfig.coffee.modules =

			files: [
				cwd: 'client'
				src: [
					'packages.coffee'
					'require.coffee'
					'modules/**/*.coffee'
				]
				dest: 'build/js/app'
				expand: true
				ext: '.js'
			,
				src: [
					'{custom,packages}/*/client/**/*.coffee'
				]
				dest: 'build/js/app'
				expand: true
				ext: '.js'
			]

		gruntConfig.concat.modules =

			files: [
				src: [
					'build/js/app/{modules,packages,require}.js'
				]
				dest: 'build/js/app/modules.js'
			]

		gruntConfig.copy.modules =

			files: [
				expand: true
				cwd: 'client/modules'
				src: ['**/*.js']
				dest: 'build/js/app/modules'
			,
				expand: true
				src: ['{custom,packages}/*/client/**/*.js']
				dest: 'build/js/app'
			]

		gruntConfig.watch.modules =

			files: [
				'client/{packages,require}.coffee'
				'client/modules/**/*.coffee'
				'{custom,packages}/*/client/**/*.coffee'
			]
			tasks: [
				'build:modules', 'build:shrub'
			]
			options: livereload: true

		gruntConfig.wrap.modules =

			files: [
				src: [
					'build/js/app/modules/**/*.js'
					'build/js/app/{custom,packages}/*/client/**/*.js'
				]
				dest: 'build/js/app/modules.js'
			]
			options:
				indent: '  '
				wrapper: (filepath) ->

					matches = filepath.match /build\/js\/app\/([^/]+)\/(.*)/

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

			files: ['build/js/app/modules.js'].map (file) -> src: file, dest: file
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
