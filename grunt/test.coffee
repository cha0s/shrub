path = require 'path'

module.exports = (grunt, config) ->
	
	testCoffees = for directory in ['controllers', 'directives', 'filters', 'services']
		"test/unit/coffee/#{directory}/*.coffee"
	testCoffeeMapping = grunt.file.expandMapping testCoffees, 'test/unit/js/',
		rename: (destBase, destPath) ->
			destPath = destPath.replace 'test/unit/coffee/', ''
			destBase + destPath.replace /\.coffee$/, '.js'
	
	testConcat = for directory in ['controllers', 'directives', 'filters', 'services']
		src: "test/unit/js/#{directory}/*.js"
		dest: "test/unit/js/#{directory}.js"
	
	testE2eCoffees = [
		'test/e2e/**/*.coffee'
	]
	testE2eCoffeeMapping = grunt.file.expandMapping testE2eCoffees, 'test/e2e/js/',
		rename: (destBase, destPath) ->
			destPath = destPath.replace 'test/e2e/coffee/', ''
			destBase + destPath.replace /\.coffee$/, '.js'
	
	config.coffee ?= {}
	
	config.clean.test = [
		'test/unit/js/controllers.js'
		'test/unit/js/directives.js'
		'test/unit/js/filters.js'
		'test/unit/js/services.js'
	]
	
	config.clean.testBuild = testCoffeeMapping.map (file) -> file.dest
	
	config.clean.testE2e = [
		'test/e2e/scenarios.js'
	]
	
	config.clean.testE2eBuild = testE2eCoffeeMapping.map (file) -> file.dest
	
	config.coffee.test = files: testCoffeeMapping
	
	config.coffee.testE2e =
		files: testE2eCoffeeMapping
	
	config.concat.test = files: testConcat
	
	config.concat.testE2e =
		src: testE2eCoffeeMapping.map (file) -> file.dest
		dest: 'test/e2e/scenarios.js'
	
	wrappedTestFiles = ['controllers', 'directives', 'filters', 'services'].map (directory) -> "test/unit/js/#{directory}.js"
	
	config.wrap.test =
		files: wrappedTestFiles.map (file) -> src: file, dest: file
		options:
			wrapper: (filepath) ->
				
				extname = path.extname filepath
				moduleType = path.basename filepath, extname
				
				[
					"""
'use strict';

describe('#{moduleType}', function() {

  beforeEach(function() {
    module('AngularShrub.controllers');
    module('AngularShrub.directives');
    module('AngularShrub.filters');
    module('AngularShrub.services');
    module('AngularShrub.require');
    module('AngularShrub.mocks');
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
	