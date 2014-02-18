path = require 'path'

module.exports = (grunt, config) ->
	
	unitCoffees = [
		'client/**/test-unit.coffee'
	]
	unitCoffeeMapping = grunt.file.expandMapping unitCoffees, 'build/js/',
		rename: (destBase, destPath) ->
			destPath = destPath.replace 'client/', ''
			destBase + destPath.replace /\.coffee$/, '.js'
	
	e2eCoffees = [
		'client/**/test-e2e.coffee'
	]
	e2eCoffeeMapping = grunt.file.expandMapping e2eCoffees, 'build/js/',
		rename: (destBase, destPath) ->
			destPath = destPath.replace 'client/', ''
			destBase + destPath.replace /\.coffee$/, '.js'
			
	config.clean ?= {}
	config.coffee ?= {}
	config.concat ?= {}
	config.copy ?= {}
	config.watch ?= {}
	config.wrap ?= {}
	
	config.clean.unit = [
		'test/unit/tests.js'
	]
	
	config.clean.unitBuild = unitCoffeeMapping.map (file) -> file.dest
	
	config.clean.e2e = [
		'test/e2e/scenarios.js'
	]
	
	config.clean.e2eBuild = e2eCoffeeMapping.map (file) -> file.dest
	
	config.coffee.unit = files: unitCoffeeMapping
	
	config.coffee.e2e =
		files: e2eCoffeeMapping
	
	config.concat.unit =
		src: unitCoffeeMapping.map (file) -> file.dest
		dest: 'test/unit/tests.js'
	
	config.concat.e2e =
		src: e2eCoffeeMapping.map (file) -> file.dest
		dest: 'test/e2e/scenarios.js'
	
	config.copy.e2e =
		expand: true
		cwd: 'client'
		src: ['**/test-e2e.js']
		dest: 'build/js'
	
	config.copy.unit =
		expand: true
		cwd: 'client'
		src: ['**/test-unit.js']
		dest: 'build/js'
	
	config.watch.e2e =
		files: e2eCoffees.concat ['client/**/test-e2e.js']
		tasks: 'compile-tests-e2e'
	
	config.watch.unit =
		files: unitCoffees.concat ['client/**/test-unit.js']
		tasks: 'compile-tests-unit'
	
	config.wrap.unit =
		files: ['test/unit/tests.js'].map (file) -> src: file, dest: file
		options:
			indent: '  '
			wrapper: [
				"""
'use strict';

describe('#{config.pkg.name}', function() {

  beforeEach(function() {
    module('shrub.config');
    module('shrub.packages');
    module('shrub.require');
  });


"""
				"""

});
"""
			]
	
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
	
	grunt.registerTask 'compile-tests-e2e', [
		'coffee:e2e'
		'copy:e2e'
		'concat:e2e'
		'wrap:e2e'
		'clean:e2eBuild'
	]
	
	grunt.registerTask 'compile-tests-unit', [
		'coffee:unit'
		'copy:unit'
		'concat:unit'
		'wrap:unit'
		'clean:unitBuild'
	]
	
	grunt.registerTask 'compile-tests', [
		'compile-tests-e2e'
		'compile-tests-unit'
	]
	
	config.shrub.tasks['compile-coffee'].push 'compile-tests'
	