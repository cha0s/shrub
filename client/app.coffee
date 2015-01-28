
# # Application entry point.

# Top-level module.
angular.module 'shrub', ['shrub.core']

coreDependencies = []

coreDependencies.push 'ngRoute'
coreDependencies.push 'ngSanitize'

coreDependencies.push dependencies... if dependencies?

coreDependencies.push 'shrub.config'
coreDependencies.push 'shrub.packages'
coreDependencies.push 'shrub.require'

 # Core module: pulls in some Angular modules, and our own modules.
angular.module('shrub.core', coreDependencies)

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
