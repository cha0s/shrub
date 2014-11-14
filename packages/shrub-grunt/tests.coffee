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
		
			spawn(
				"#{__dirname}/../../scripts/e2e-test.sh"
				[]
				stdio: 'inherit'
			).on 'close', @async()
		
		gruntConfig.shrub.tasks['tests:e2e'] = [
			'build'
			'tests:e2eFunction'
		]
		
		gruntConfig.shrub.tasks['tests:unitFunction'] = ->
		
			spawn(
				"#{__dirname}/../../scripts/test.sh"
				['--single-run']
				stdio: 'inherit'
			).on 'close', @async()
		
		gruntConfig.shrub.tasks['tests:unit'] = [
			'build'
			'tests:unitFunction'
			'tests:e2eFunction'
		]
		
		gruntConfig.shrub.tasks['tests'] = [
			 'tests:unit'
		]
		
	# ## Implements hook `gruntConfigAlter`
	registrar.registerHook 'gruntConfigAlter', (gruntConfig) ->
	
		gruntConfig.watch.modules.files.push '!client/modules/**/test-e2e.coffee'
		gruntConfig.watch.modules.files.push '!custom/*/client/**/test-e2e.coffee'
		gruntConfig.watch.modules.files.push '!packages/*/client/**/test-e2e.coffee'
	
		src = gruntConfig.coffee.modules.files[0].src
		
		src.push '!modules/**/test-e2e.coffee'
		src.push '!modules/**/test-unit.coffee'
		src.push '!modules/**/*.spec.coffee'

		src = gruntConfig.coffee.modules.files[1].src

		src.push  '!custom/*/client/**/test-e2e.coffee'
		src.push  '!custom/*/client/**/test-unit.coffee'
		src.push  '!custom/*/client/**/*.spec.coffee'
	
		src.push  '!packages/*/client/**/test-e2e.coffee'
		src.push  '!packages/*/client/**/test-unit.coffee'
		src.push  '!packages/*/client/**/*.spec.coffee'
