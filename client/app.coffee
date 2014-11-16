'use strict'

# # Application entry point.

# Top-level module, includes UI as well as core.
angular.module 'shrub', [
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
		'$injector', 'shrub-pkgmanProvider'
		({invoke}, {invokeFlat}) ->
			
			# Invoke hook `appConfig`.
			# Invoked when the Angular application is in the configuration
			# phase.
			invoke injectable for injectable in invokeFlat 'appConfig'
			
	])
	
	.run([
	
		'$injector', 'shrub-pkgman'
		({invoke}, {invokeFlat}) ->
			
			# Invoke hook `appRun`.
			# Invoked when the Angular application is run.
			invoke injectable for injectable in invokeFlat 'appRun'

	])
