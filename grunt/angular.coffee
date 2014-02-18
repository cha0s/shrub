path = require 'path'

module.exports = (grunt, config) ->
	
	angularCoffees = [
		'client/app.coffee'
	]
	
	angularCoffeeMapping = grunt.file.expandMapping angularCoffees, 'build/js/',
		rename: (destBase, destPath) ->
			destPath = destPath.replace 'client/', ''
			destBase + destPath.replace /\.coffee$/, '.js'
			
	config.clean ?= {}
	config.coffee ?= {}
	config.watch ?= {}
	
	config.clean.angular = [
		'build/js/app.js'
	]
	
	config.coffee.angular = files: angularCoffeeMapping
	
	config.watch.angular =
		files: angularCoffees
		tasks: 'compile-angular'
		
	grunt.registerTask 'compile-angular', [
		'coffee:angular'
	]
	
	config.shrub.tasks['compile-coffee'].push 'compile-angular'
	