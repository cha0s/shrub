'use strict'

angular.module('shrub', [
	'ngRoute'
	'ngSanitize'
	
	'ui.bootstrap'
	
	'shrub.config'
	'shrub.packages'
	'shrub.require'
]).

	config([
		'$injector', 'pkgmanProvider'
		($injector, pkgmanProvider) ->
			
			pkgmanProvider.invoke 'appConfig', (_, fn) -> $injector.invoke fn
			
	])
	
	.run([
	
		'$injector', 'pkgman'
		($injector, pkgman) ->
			
			pkgman.invoke 'appRun', (_, fn) -> $injector.invoke fn

	])
