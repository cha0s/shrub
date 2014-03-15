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
			
			for _, injected of pkgmanProvider.invokeWithMocks 'appConfig'
				$injector.invoke injected
			
	])
	
	.run([
	
		'$injector', 'pkgman'
		($injector, pkgman) ->
			
			for _, injected of pkgman.invokeWithMocks 'appRun'
				$injector.invoke injected

	])
