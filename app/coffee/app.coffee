'use strict'

angular.module('Shrub', [
	'ngRoute'
	'ngSanitize'
	
	'shrub.mocks'
	'shrub.packages'
	
	'shrub.require'
	
	'$strap.directives'
]).

	config([
		'$injector', 'requireProvider'
		($injector, requireProvider) ->
			
			pkgman = requireProvider.require 'pkgman'
			pkgman.invoke 'appConfig', (_, fn) -> $injector.invoke fn
			
	])
	
# Application initialization.
	.run([
	
		'$injector', 'require'
		($injector, require) ->
			
			pkgman = require 'pkgman'
			pkgman.invoke 'appRun', (_, fn) -> $injector.invoke fn

	])
