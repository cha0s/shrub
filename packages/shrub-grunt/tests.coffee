path = require 'path'
child_process = require 'child_process'

tcpPortUsed = require 'tcp-port-used'

bootstrap = require 'bootstrap'

shrubConfig = require 'shrub-config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->

		{grunt} = gruntConfig

		gruntConfig.coffee ?= {}
		gruntConfig.concat ?= {}
		gruntConfig.copy ?= {}
		gruntConfig.jasmine ?= {}
		gruntConfig.karma ?= {}
		gruntConfig.protractor ?= {}
		gruntConfig.watch ?= {}
		gruntConfig.wrap ?= {}

		gruntConfig.coffee.testsE2e =

			files: [
				src: [
					'client/modules/**/test-e2e.coffee'
					'{custom,packages}/*/client/**/test-e2e.coffee'
				]
				dest: 'build/js/tests'
				expand: true
				ext: '.js'
			]

		gruntConfig.coffee.testsE2eExtensions =

			files: [
				src: [
					'test/e2e/extensions/**/*.coffee'
				]
				dest: 'build/js/tests'
				expand: true
				ext: '.js'
			]

		gruntConfig.coffee.testsUnit =

			files: [
				src: [
					'client/modules/**/test-unit.coffee'
					'{custom,packages}/*/client/**/test-unit.coffee'
				]
				dest: 'build/js/tests'
				expand: true
				ext: '.js'
			]

		gruntConfig.concat.testsE2e =

			files: [
				src: [
					'build/js/tests/**/test-e2e.js'
				]
				dest: 'build/js/tests/test/scenarios-raw.js'
			]

		gruntConfig.concat.testsE2eExtensions =

			files: [
				src: [
					'build/js/tests/test/e2e/extensions/**/*.js'
				]
				dest: 'test/e2e/extensions.js'
			]

		gruntConfig.concat.testsUnit =

			files: [
				src: [
					'build/js/tests/**/test-unit.js'
				]
				dest: 'build/js/tests/test/tests-raw.js'
			]

		gruntConfig.copy.testsE2e =

			files: [
				src: [
					'client/modules/**/test-e2e.js'
					'{custom,packages}/*/client/**/test-e2e.js'
				]
				dest: 'build/js/tests'
			]

		gruntConfig.copy.testsUnit =

			files: [
				src: [
					'client/modules/**/test-unit.js'
					'{custom,packages}/*/client/**/test-unit.js'
				]
				dest: 'build/js/tests'
			]

		gruntConfig.karma.testsUnit =

			options:

				basePath: "#{__dirname}/../.."

				files: [
					'app/lib/angular/angular.js'
					'app/lib/angular/angular-*.js'
					'test/lib/angular/angular-mocks.js'
					'app/lib/shrub/shrub.js'
					'test/unit/config.js'
					'test/unit/tests.js'
				]

				exclude: [
					'app/lib/angular/angular-loader.js'
					'app/lib/angular/*.min.js'
					'app/lib/angular/angular-scenario.js'
				]

				frameworks: [
					'jasmine'
				]

				browsers: [
					'Chrome'
				]

				plugins: [
					'karma-junit-reporter'
					'karma-chrome-launcher'
					'karma-firefox-launcher'
					'karma-jasmine'
				]

				singleRun: true

				junitReporter:

					outputFile: 'test_out/unit.xml'
					suite: 'unit'

		gruntConfig.protractor.testsE2e =

			options:

				configFile: 'config/protractor.conf.js'
				keepAlive: false
				noColor: true

		gruntConfig.watch.testsE2e =

			files: [
				'client/modules/**/test-e2e.coffee'
				'{custom,packages}/*/client/**/test-e2e.coffee'
			]
			tasks: ['build:testsE2e']

		gruntConfig.watch.testsE2eExtensions =

			files: [
				'test/e2e/extensions/**/*.coffee'
			]
			tasks: ['build:testsE2eExtensions']

		gruntConfig.watch.testsUnit =

			files: [
				'client/modules/**/test-unit.coffee'
				'{custom,packages}/*/client/**/test-unit.coffee'
			]
			tasks: ['build:testsUnit']

		gruntConfig.wrap.testsE2e =
			files: [
				src: [
					'build/js/tests/test/scenarios-raw.js'
				]
				dest: 'test/e2e/scenarios.js'
			]
			options:
				indent: '  '
				wrapper: [
					'''
'use strict';

describe('#{gruntConfig.pkg.name}', function() {


'''
					'''

});
'''
				]

		gruntConfig.wrap.testsUnit =
			files: [
				src: [
					'build/js/tests/test/tests-raw.js'
				]
				dest: 'test/unit/tests.js'
			]
			options:
				indent: '  '
				wrapper: [
					'''
'use strict';

describe('#{gruntConfig.pkg.name}', function() {

  beforeEach(function() {
    module('shrub.core');
  });


'''
					'''

});
'''
				]

		gruntConfig.shrub.tasks['build:testsE2e'] = [
			'newer:coffee:testsE2e'
			'newer:copy:testsE2e'
			'concat:testsE2e'
			'wrap:testsE2e'
		]

		gruntConfig.shrub.tasks['build:testsE2eExtensions'] = [
			'newer:coffee:testsE2eExtensions'
			'concat:testsE2eExtensions'
		]

		gruntConfig.shrub.tasks['build:testsUnit'] = [
			'newer:coffee:testsUnit'
			'newer:copy:testsUnit'
			'concat:testsUnit'
			'wrap:testsUnit'
		]

		gruntConfig.shrub.tasks['build:tests'] = [
			'build:testsE2e'
			'build:testsE2eExtensions'
			'build:testsUnit'
		]

		e2eServerChild = null

		gruntConfig.shrub.tasks['tests:e2eServerUp'] = ->

			done = @async()

			bootstrap.openServerPort().then (port) ->

				# Pass arguments to the child process.
				args = process.argv.slice 2

				# Pass the environment to the child process.
				options = env: process.env
				options.env['E2E'] = 'true'
				options.env['packageSettings:shrub-http:port'] = port

				# Fork it
				e2eServerChild = child_process.fork(
					"#{__dirname}/../../node_modules/coffee-script/bin/coffee"
					["#{__dirname}/../../server.coffee"]
					options
				)

				# Inject the port configuration.
				baseUrl = "http://localhost:#{port}/"
				gruntConfig.protractor.testsE2e.options.args = baseUrl: baseUrl

				# Wait for the server to come up.
				grunt.log.write 'Waiting for E2E server to come up...'
				tcpPortUsed.waitUntilUsed(port, 400, 30000).then(

					->
						grunt.task.run 'protractor:testsE2e'
						done()

					(error) -> grunt.fail.fatal 'E2E server never came up after 30 seconds!'
				)

		gruntConfig.shrub.tasks['tests:e2eServerDown'] = ->
			e2eServerChild.on 'close', @async()
			e2eServerChild.kill()

		gruntConfig.shrub.tasks['tests:e2e'] = [
			'buildOnce'
			'tests:e2eServerUp'
			'tests:e2eServerDown'
		]

		gruntConfig.shrub.tasks['tests:unitConfig'] = ->

			done = @async()

			req = grunt: true

			shrubConfig.renderPackageConfig(req).then (code) ->

				grunt.file.write 'test/unit/config.js', code

				done()

		gruntConfig.shrub.tasks['tests:unit'] = [
			'buildOnce'
			'tests:unitConfig'
			'karma:testsUnit'
		]

		gruntConfig.shrub.tasks['tests:jasmineFunction'] = ->

			done = @async()

			# Spawn node Jasmine
			child_process.spawn(
				'node'
				[
					"#{__dirname}/../../node_modules/jasmine-node/lib/jasmine-node/cli.js"
					'--coffee', 'client', 'packages', 'custom'
				]
				stdio: 'inherit'
			).on 'close', (code) ->
				return done() if code is 0
				grunt.fail.fatal 'Jasmine tests not passing!'

		gruntConfig.shrub.tasks['tests:jasmine'] = [
			'buildOnce'
			'tests:jasmineFunction'
		]

		gruntConfig.shrub.tasks['tests'] = [
			 'tests:jasmine'
			 'tests:unit'
			 'tests:e2e'
		]

		gruntConfig.shrub.tasks['build'].push 'build:tests'

		gruntConfig.shrub.npmTasks.push 'grunt-karma'
		gruntConfig.shrub.npmTasks.push 'grunt-protractor-runner'

	# ## Implements hook `gruntConfigAlter`
	registrar.registerHook 'gruntConfigAlter', (gruntConfig) ->

		ignoreFiles = (array, directory) ->
			array.push "!#{directory}/**/#{spec}" for spec in [
				'test-{e2e,unit}.coffee'
				'*.spec.coffee'
			]

		for directory in [
			'client/modules'
			'{custom,packages}/*/client'
		]
			ignoreFiles gruntConfig.watch.modules.files, directory

		files = gruntConfig.coffee.modules.files
		ignoreFiles files[0].src, 'modules'
		ignoreFiles files[1].src, 'custom/*/client'
		ignoreFiles files[1].src, 'packages/*/client'
