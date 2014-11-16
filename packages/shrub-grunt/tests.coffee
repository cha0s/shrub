path = require 'path'

{spawn} = require 'child_process'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->
	
		gruntConfig.clean ?= {}
		gruntConfig.coffee ?= {}
		gruntConfig.concat ?= {}
		gruntConfig.copy ?= {}
		gruntConfig.watch ?= {}
		gruntConfig.wrap ?= {}
		
		gruntConfig.clean.testsE2e = [
			'build/js/client/modules/**/test-e2e.js'
			'build/js/custom/*/client/**/test-e2e.js'
			'build/js/packages/*/client/**/test-e2e.js'
			'build/js/test/scenarios-raw.js'
			'test/e2e/scenarios.js'
			'test/unit/tests.js'
		]

		gruntConfig.clean.testsE2eExtensions = [
			'build/js/test/e2e/extensions/**/*.js'
		]

		gruntConfig.clean.testsE2eUnit = [
			'build/js/client/modules/**/test-unit.coffee'
			'build/js/custom/*/client/**/test-unit.coffee'
			'build/js/packages/*/client/**/test-unit.coffee'
			'build/js/test/tests-raw.js'
		]

		gruntConfig.coffee.testsE2e =
		
			files: [
				src: [
					'client/modules/**/test-e2e.coffee'
					'custom/*/client/**/test-e2e.coffee'
					'packages/*/client/**/test-e2e.coffee'
				]
				dest: 'build/js'
				expand: true
				ext: '.js'
			]
		
		gruntConfig.coffee.testsE2eExtensions =
		
			files: [
				src: [
					'test/e2e/extensions/**/*.coffee'
				]
				dest: 'build/js'
				expand: true
				ext: '.js'
			]
		
		gruntConfig.coffee.testsUnit =
		
			files: [
				src: [
					'client/modules/**/test-unit.coffee'
					'custom/*/client/**/test-unit.coffee'
					'packages/*/client/**/test-unit.coffee'
				]
				dest: 'build/js'
				expand: true
				ext: '.js'
			]
		
		gruntConfig.concat.testsE2e =
		
			files: [
				src: [
					'build/js/**/test-e2e.js'
				]
				dest: 'build/js/test/scenarios-raw.js'
			]
		
		gruntConfig.concat.testsE2eExtensions =
		
			files: [
				src: [
					'build/js/test/e2e/extensions/**/*.js'
				]
				dest: 'test/e2e/extensions.js'
			]
		
		gruntConfig.concat.testsUnit =
		
			files: [
				src: [
					'build/js/**/test-unit.js'
				]
				dest: 'build/js/test/tests-raw.js'
			]
		
		gruntConfig.copy.testsE2e =

			files: [
				src: [
					'client/modules/**/test-e2e.js'
					'custom/*/client/**/test-e2e.js'
					'packages/*/client/**/test-e2e.js'
				]
				dest: 'build/js'
			]
		
		gruntConfig.copy.testsUnit =
		
			files: [
				src: [
					'client/modules/**/test-unit.js'
					'custom/*/client/**/test-unit.js'
					'packages/*/client/**/test-unit.js'
				]
				dest: 'build/js'
			]
		
		gruntConfig.watch.testsE2e =

			files: [
				'client/modules/**/test-e2e.coffee'
				'custom/*/client/**/test-e2e.coffee'
				'packages/*/client/**/test-e2e.coffee'
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
				'custom/*/client/**/test-unit.coffee'
				'packages/*/client/**/test-unit.coffee'
			]
			tasks: ['build:testsUnit']
		
		gruntConfig.wrap.testsE2e =
			files: [
				src: [
					'build/js/test/scenarios-raw.js'
				]
				dest: 'test/e2e/scenarios.js'
			]
			options:
				indent: '  '
				wrapper: [
					"""
'use strict';

describe('#{gruntConfig.pkg.name}', function() {


"""
					"""

});
"""
				]
		
		gruntConfig.wrap.testsUnit =
			files: [
				src: [
					'build/js/test/tests-raw.js'
				]
				dest: 'test/unit/tests.js'
			]
			options:
				indent: '  '
				wrapper: [
					"""
'use strict';

describe('#{gruntConfig.pkg.name}', function() {

  beforeEach(function() {
    module('shrub.core');
  });


"""
					"""

});
"""
				]
		
		gruntConfig.shrub.tasks['build:testsE2e'] = [
			'coffee:testsE2e'
			'copy:testsE2e'
			'concat:testsE2e'
			'wrap:testsE2e'
		]
		
		gruntConfig.shrub.tasks['build:testsE2eExtensions'] = [
			'coffee:testsE2eExtensions'
			'concat:testsE2eExtensions'
		]
		
		gruntConfig.shrub.tasks['build:testsUnit'] = [
			'coffee:testsUnit'
			'copy:testsUnit'
			'concat:testsUnit'
			'wrap:testsUnit'
		]
		
		gruntConfig.shrub.tasks['build:tests'] = [
			'build:testsE2e'
			'build:testsE2eExtensions'
			'build:testsUnit'
		]
		
		gruntConfig.shrub.tasks['build'].push 'build:tests'
		
		gruntConfig.shrub.tasks['tests:e2eFunction'] = ->
			
			done = @async()
			
			spawn(
				"#{__dirname}/../../scripts/e2e-test.sh"
				[]
				stdio: 'inherit'
			).on 'close', (code) ->
				
				return done() if code is 0
					
				gruntConfig.grunt.fail.fatal "End-to-end tests failed", 1

		built = false
		
		gruntConfig.shrub.tasks['tests:e2e'] = ->
			
			unless built
				built = true
				gruntConfig.grunt.task.run 'build'
				
			gruntConfig.grunt.task.run 'tests:e2eFunction'
		
		gruntConfig.shrub.tasks['tests:unitFunction'] = ->
			
			done = @async()
			
			spawn(
				"#{__dirname}/../../scripts/test.sh"
				['--single-run']
				stdio: 'inherit'
			).on 'close', (code) ->
				
				return done() if code is 0
					
				gruntConfig.grunt.fail.fatal "Unit tests failed", 1
		
		gruntConfig.shrub.tasks['tests:unit'] = -> 
		
			unless built
				built = true
				gruntConfig.grunt.task.run 'build'
				
			gruntConfig.grunt.task.run 'tests:unitFunction'

		gruntConfig.shrub.tasks['tests'] = [
			 'tests:unit'
			 'tests:e2e'
		]
		
	# ## Implements hook `gruntConfigAlter`
	registrar.registerHook 'gruntConfigAlter', (gruntConfig) ->
		
		ignoreFiles = (array, directory) ->
			array.push "!#{directory}/**/#{spec}" for spec in [
				'test-e2e.coffee'
				'test-unit.coffee'
				'*.spec.coffee'
			]
		
		for directory in [
			'client/modules'
			'custom/*/client'
			'packages/*/client'
		]
			ignoreFiles gruntConfig.watch.modules.files, directory
	
		files = gruntConfig.coffee.modules.files
		ignoreFiles files[0].src, 'modules'
		ignoreFiles files[1].src, 'custom/*/client'
		ignoreFiles files[1].src, 'packages/*/client'
