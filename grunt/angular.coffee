path = require 'path'

module.exports = (grunt, config) ->
	
	angularCoffees = [
		'app/coffee/app.coffee'
	]
	for directory in ['controllers', 'directives', 'filters', 'mocks', 'services']
		angularCoffees.push "app/coffee/#{directory}/*.coffee"
	angularCoffeeMapping = grunt.file.expandMapping angularCoffees, 'app/js/',
		rename: (destBase, destPath) ->
			destPath = destPath.replace 'app/coffee/', ''
			destBase + destPath.replace /\.coffee$/, '.js'
	angularEmptyMock =
		src: 'app/coffee/empty-mocks.coffee'
		dest: 'app/js/empty-mocks.js'
	
	parseAngularModuleTypeAndName = (filepath) ->
	
		matches = filepath.match /^app\/js\/(.*)\/(.*\.js)$/
		
		moduleType: matches[1]
		moduleName: path.basename filepath, path.extname matches[2]
		
	angularModules = []
	angularModulesByType = {}
	for mapping in angularCoffeeMapping
		
		matches = mapping.dest.match /^app\/js\/(controllers|directives|filters|mocks|services)/
		continue unless matches?.length
		
		(angularModulesByType[matches[1]] ?= []).push mapping.dest
		
		angularModules.push mapping.dest
	
	angularModuleConcat = for directory in ['controllers', 'directives', 'filters', 'mocks', 'services']
		src: "app/js/#{directory}/*.js"
		dest: "app/js/#{directory}.js"
	
	config.clean ?= {}
	config.concat ?= {}
	config.coffee ?= {}
	config.uglify ?= {}
	config.watch ?= {}
	config.wrap ?= {}
	
	config.clean.angular = [
		'app/js/app.js'
		'app/js/controllers.js'
		'app/js/directives.js'
		'app/js/filters.js'
		'app/js/services.js'
		'app/js/mocks.js'
		'app/js/empty-mocks.js'
		'app/js/angular.min.js'
	]
	
	angularBuildClean = angularCoffeeMapping.map (file) -> file.dest
	angularBuildClean.push '!app/js/app.js'
	config.clean.angularBuild = angularBuildClean
	
	config.coffee.angular = files: angularCoffeeMapping.concat [angularEmptyMock]
	
	config.concat.angularModules = files: angularModuleConcat
	
	config.uglify.angular =
		files:
			'app/js/angular.min.js': [
				'app/js/app.js'
				'app/js/controllers.js'
				'app/js/directives.js'
				'app/js/filters.js'
				'app/js/services.js'
				'app/js/empty-mocks.js'
			]
				
	config.watch.angular =
		files: angularCoffees
		tasks: 'compile-angular'
		
	config.wrap.angularControllers =
		files: ['app/js/controllers.js'].map (file) -> src: file, dest: file
		wrapper: [
			"'use strict';\n\n"
			''
		]
			
	config.wrap.angularModules =
		files: angularModules.map (file) -> src: file, dest: file
		options:
			indent: '    '
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

	angularParentModuleFiles = ("app/js/#{type}.js" for type in [
		'controllers', 'directives', 'filters', 'mocks', 'services'
	])
	config.wrap.angularParentModules =
		files: angularParentModuleFiles.map (file) -> src: file, dest: file
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

  angular.module('Shrub.#{moduleType}', #{moduleNames});

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
		'wrap:angularControllers'
		'clean:angularBuild'
	]
	
	config.shrub.tasks['compile-coffee'].push 'compile-angular'
	