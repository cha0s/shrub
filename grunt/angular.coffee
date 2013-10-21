path = require 'path'

module.exports = (grunt, config) ->
	
	angularCoffees = [
		'app/coffee/app.coffee'
	]
	
	directories = [
		'controllers', 'directives', 'filters', 'mocks', 'services'
	]
	
	for directory in directories
		angularCoffees.push "app/coffee/#{directory}/**/*.coffee"
	angularCoffeeMapping = grunt.file.expandMapping angularCoffees, 'app/js/',
		rename: (destBase, destPath) ->
			destPath = destPath.replace 'app/coffee/', ''
			destBase + destPath.replace /\.coffee$/, '.js'
			
	angularEmptyMock =
		src: 'app/coffee/empty-mocks.coffee'
		dest: 'app/js/empty-mocks.js'
	
	angularModules = []
	angularModulesByType = {}
	
	search = new RegExp "^app\/js\/(#{directories.join '|'})"
	for mapping in angularCoffeeMapping
		matches = mapping.dest.match search
		continue unless matches?.length
		
		(angularModulesByType[matches[1]] ?= []).push mapping.dest
		
		angularModules.push mapping.dest
		
	angularModuleConcat = for directory in directories
		src: "app/js/#{directory}/**/*.js"
		dest: "app/js/#{directory}.js"
		
	config.clean ?= {}
	config.concat ?= {}
	config.coffee ?= {}
	config.uglify ?= {}
	config.watch ?= {}
	config.wrap ?= {}
	
	directoryEmissions = directories.map (directory) ->
		"app/js/#{directory}.js"
	
	config.clean.angular = [
		'app/js/app.js'
		'app/js/empty-mocks.js'
		'app/js/angular.min.js'
	].concat directoryEmissions
	
	angularBuildClean = angularCoffeeMapping.map (file) -> file.dest
	angularBuildClean.push '!app/js/app.js'
	config.clean.angularBuild = angularBuildClean
	
	config.coffee.angular = files: angularCoffeeMapping.concat [angularEmptyMock]
	
	config.concat.angularModules = files: angularModuleConcat
	
	uglifiedEmissions = directoryEmissions.map (file) ->
		if file is 'app/js/mocks.js'
			'app/js/empty-mocks.js'
		else
			file
	config.uglify.angular =
		files:
			'app/js/angular.min.js': [
				'app/js/app.js'
			].concat uglifiedEmissions
				
	config.watch.angular =
		files: angularCoffees
		tasks: 'compile-angular'
		
	parseAngularModuleTypeAndName = (filepath) ->
		
		parts = path.dirname(filepath).split path.sep
		parts.push path.basename filepath, '.js'
		
		moduleType: parts[2]
		moduleName: parts.slice(3).join '.'
		
	config.wrap.angularModules =
		files: angularModules.map (file) -> src: file, dest: file
		options:
			indent: '  '
			wrapper: (filepath) ->
				
				{moduleType, moduleName} = parseAngularModuleTypeAndName filepath
				
				[
					"""

(function() {

  var $module = angular.module('#{config.pkg.name}.#{moduleType}.#{moduleName}', []);


"""						
					"""

})();
"""						
				]

	config.wrap.angularParentModules =
		files: directoryEmissions.map (file) -> src: file, dest: file
		options:
			indent: '  '
			wrapper: (filepath) ->
			
				extname = path.extname filepath
				moduleType = path.basename filepath, extname
				
				moduleNames = []
				for module in angularModulesByType[moduleType] ? []
					{moduleName} = parseAngularModuleTypeAndName module
					moduleNames.push moduleName
				
				if moduleNames.length	
					moduleNames = moduleNames.map (moduleName) ->
						"#{config.pkg.name}.#{moduleType}.#{moduleName}"
						
					moduleNames = "[\n    '#{moduleNames.join "',\n    '"}'\n  ]"
				
				else
					
					moduleNames = '[]'
				
				[
					"""
(function() {
  'use strict';

  angular.module('shrub.#{moduleType}', #{moduleNames});

"""						
					"""


})();

"""						
				]
					
	grunt.registerTask 'compile-angular', [
		'coffee:angular'
		'wrap:angularModules'
		'concat:angularModules'
		'wrap:angularParentModules'
		'clean:angularBuild'
	]
	
	config.shrub.tasks['compile-coffee'].push 'compile-angular'
	