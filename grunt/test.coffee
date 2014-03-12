path = require 'path'

module.exports = (grunt, config) ->
	
	e2eCoffeeMapping = grunt.shrub.coffeeMapping e2eCoffees = [
		'client/**/test-e2e.coffee'
	], 'build/js/test'
	
	e2eExtensionsCoffeeMapping = grunt.shrub.coffeeMapping e2eExtensionsCoffees = [
		'test/e2e/extensions/**/*.coffee'
	], 'build/js'
	
	unitCoffeeMapping = grunt.shrub.coffeeMapping unitCoffees = [
		'client/**/test-unit.coffee'
	], 'build/js/test'
	
	config.clean ?= {}
	config.coffee ?= {}
	config.concat ?= {}
	config.copy ?= {}
	config.watch ?= {}
	config.wrap ?= {}
	
	config.clean.e2e = [
		'test/e2e/scenarios.js'
	]
	
	config.clean.e2eExtensions = [
		'test/e2e/extensions.js'
	]
	
	config.clean.unit = [
		'test/unit/tests.js'
	]
	
	config.clean.testsBuild = [
		'build/js/test'
	]
	
	config.coffee.e2e = files: e2eCoffeeMapping
	
	config.coffee.e2eExtensions = files: e2eExtensionsCoffeeMapping
	
	config.coffee.unit = files: unitCoffeeMapping
	
	config.concat.e2e =
		src: e2eCoffeeMapping.map (file) -> file.dest
		dest: 'test/e2e/scenarios.js'
	
	config.concat.e2eExtensions =
		src: e2eExtensionsCoffeeMapping.map (file) -> file.dest
		dest: 'test/e2e/extensions.js'
	
	config.concat.unit =
		src: unitCoffeeMapping.map (file) -> file.dest
		dest: 'test/unit/tests.js'
	
	config.copy.e2e =
		expand: true
		cwd: 'client'
		src: ['**/test-e2e.js']
		dest: 'build/js/test'
	
	config.copy.unit =
		expand: true
		cwd: 'client'
		src: ['**/test-unit.js']
		dest: 'build/js/test'
	
	config.watch.e2e =
		files: e2eCoffees.concat ['client/**/test-e2e.js']
		tasks: ['compile-tests-e2e', 'clean:testsBuild']
	
	config.watch.e2eExtensions =
		files: e2eExtensionsCoffees.concat ['test/e2e/extensions/**/*.js']
		tasks: ['compile-tests-e2eExtensions', 'clean:testsBuild']
	
	config.watch.unit =
		files: unitCoffees.concat ['client/**/test-unit.js']
		tasks: ['compile-tests-unit', 'clean:testsBuild']
	
	config.wrap.e2e =
		files: ['test/e2e/scenarios.js'].map (file) -> src: file, dest: file
		options:
			indent: '  '
			wrapper: [
				"""
'use strict';

describe('#{config.pkg.name}', function() {


"""
				"""

});
"""
			]
	
	config.wrap.unit =
		files: ['test/unit/tests.js'].map (file) -> src: file, dest: file
		options:
			indent: '  '
			wrapper: [
				"""
'use strict';

describe('#{config.pkg.name}', function() {

  beforeEach(function() {
    module('shrub.core');
  });


"""
				"""

});
"""
			]
	
	grunt.registerTask 'compile-tests-e2e', [
		'coffee:e2e'
		'copy:e2e'
		'concat:e2e'
		'wrap:e2e'
	]
	
	grunt.registerTask 'compile-tests-e2eExtensions', [
		'coffee:e2eExtensions'
		'concat:e2eExtensions'
	]
	
	grunt.registerTask 'compile-tests-unit', [
		'coffee:unit'
		'copy:unit'
		'concat:unit'
		'wrap:unit'
	]
	
	grunt.registerTask 'compile-tests', [
		'compile-tests-e2e'
		'compile-tests-e2eExtensions'
		'compile-tests-unit'
	]
	
	config.shrub.tasks['compile-clean'].push 'clean:testsBuild'

	config.shrub.tasks['compile-coffee'].push 'compile-tests'
	