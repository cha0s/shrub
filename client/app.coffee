'use strict'

angular.module('shrub', [
	
	'ui.bootstrap'
	
	'shrub.core'
])

angular.module('shrub.core', [
	'ngRoute'
	'ngSanitize'

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
