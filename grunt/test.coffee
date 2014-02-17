path = require 'path'

module.exports = (grunt, config) ->
	
	testCoffees = [
		'app/coffee/**/test-unit.coffee'
	]
	testCoffeeMapping = grunt.file.expandMapping testCoffees, 'app/js/',
		rename: (destBase, destPath) ->
			destPath = destPath.replace 'app/coffee/', ''
			destBase + destPath.replace /\.coffee$/, '.js'
	
	testE2eCoffees = [
		'app/coffee/**/test-e2e.coffee'
	]
	testE2eCoffeeMapping = grunt.file.expandMapping testE2eCoffees, 'app/js/',
		rename: (destBase, destPath) ->
			destPath = destPath.replace 'app/coffee/', ''
			destBase + destPath.replace /\.coffee$/, '.js'
			
	config.coffee ?= {}
	
	config.clean.test = [
		'test/unit/tests.js'
	]
	
	config.clean.testBuild = testCoffeeMapping.map (file) -> file.dest
	
	config.clean.testE2e = [
		'test/e2e/scenarios.js'
	]
	
	config.clean.testE2eBuild = testE2eCoffeeMapping.map (file) -> file.dest
	
	config.coffee.test = files: testCoffeeMapping
	
	config.coffee.testE2e =
		files: testE2eCoffeeMapping
	
	config.concat.test =
		src: testCoffeeMapping.map (file) -> file.dest
		dest: 'test/unit/tests.js'
	
	config.concat.testE2e =
		src: testE2eCoffeeMapping.map (file) -> file.dest
		dest: 'test/e2e/scenarios.js'
	
	config.watch ?= {}
	
	config.watch.tests =
		files: testCoffees.concat testE2eCoffees
		tasks: 'compile-test'
	
	config.wrap.test =
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
	
	config.wrap.testE2e =
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
	
	grunt.registerTask 'compile-test', [
		'coffee:testE2e'
		'concat:testE2e'
		'wrap:testE2e'
		'clean:testE2eBuild'
		
		'coffee:test'
		'concat:test'
		'wrap:test'
		'clean:testBuild'
	]
	
	config.shrub.tasks['compile-coffee'].push 'compile-test'
	