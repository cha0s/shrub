'use strict'

# # Application entry point.

# Top-level module, includes UI as well as core.
angular.module 'shrub', [
	'ui.bootstrap'
	'shrub.core'
]

# Core module: pulls in some Angular modules, and our own modules.
angular.module('shrub.core', [
	'ngRoute'
	'ngSanitize'

	'shrub.config'
	'shrub.packages'
	'shrub.require'
])

	.config([
		'$injector', 'pkgmanProvider'
		($injector, pkgmanProvider) ->
			
			# Invoke hook `appConfig`.
			# Invoked when the Angular application is in the configuration
			# phase.
			for _, injected of pkgmanProvider.invokeWithMocks 'appConfig'
				$injector.invoke injected
			
	])
	
	.run([
	
		'$injector', 'pkgman'
		($injector, pkgman) ->
			
			# Invoke hook `appRun`.
			# Invoked when the Angular application is run.
			for _, injected of pkgman.invokeWithMocks 'appRun'
				$injector.invoke injected

	])
