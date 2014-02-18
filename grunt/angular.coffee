path = require 'path'

module.exports = (grunt, config) ->
	
	angularCoffeeMapping = grunt.shrub.coffeeMapping angularCoffees = [
		'client/app.coffee'
	]
			
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
	