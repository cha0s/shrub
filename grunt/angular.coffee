path = require 'path'

module.exports = (grunt, config) ->
	
	angularCoffees = [
		'app/coffee/app.coffee'
	]
	
	angularCoffeeMapping = grunt.file.expandMapping angularCoffees, 'app/js/',
		rename: (destBase, destPath) ->
			destPath = destPath.replace 'app/coffee/', ''
			destBase + destPath.replace /\.coffee$/, '.js'
			
	config.clean ?= {}
	config.coffee ?= {}
	config.uglify ?= {}
	config.watch ?= {}
	
	config.clean.angular = [
		'app/js/app.js'
	]
	
	config.coffee.angular = files: angularCoffeeMapping
	
	config.uglify.angular =
		files:
			'app/js/angular.min.js': [
				'app/js/app.js'
			]
				
	config.watch.angular =
		files: angularCoffees
		tasks: 'compile-angular'
		
	grunt.registerTask 'compile-angular', [
		'coffee:angular'
	]
	
	config.shrub.tasks['compile-coffee'].push 'compile-angular'
	