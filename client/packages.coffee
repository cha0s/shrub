
# A module that allows packages to provide Angular components.
angular.module('shrub.packages', [
	'shrub.require'
	'shrub.pkgman'
])

	.config([
		'$compileProvider', '$controllerProvider', '$filterProvider', '$provide', 'pkgmanProvider', 'requireProvider'
		($compileProvider, $controllerProvider, $filterProvider, $provide, {invoke}, {require}) ->
			
			config = require 'config'
			
			{defaultLogger} = require 'logging'
			
			# Use normalized names for directives and filters:
			# 'core/foo/bar' -> 'coreFooBar'
			i8n = require 'inflection'
			normalize = (path) ->
				parts = for part, i in path.split '/'
					i8n.camelize(
						part.replace /[^\w]/g, '_'
						0 is i
					)
					
				i8n.camelize (i8n.underscore parts.join ''), true

			# Invoke hook `controller`.
			# Allows packages to define Angular controllers. Implementations
			# should return an [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation).
			defaultLogger.info "Registering controllers..."
			
			for path, injected of invoke 'controller'
				defaultLogger.info path
				
				$controllerProvider.register path, injected

			defaultLogger.info "Controllers registered."

			# Invoke hook `directive`.
			# Allows packages to define Angular directives. Implementations
			# should return an [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation).
			defaultLogger.info "Registering directives..."
			
			for path, injected of invoke 'directive'
				defaultLogger.info normalize path

				$compileProvider.directive (normalize path), injected

			defaultLogger.info "Directives registered."

			# Invoke hook `filter`.
			# Allows packages to define Angular filters. Implementations
			# should return a function.
			defaultLogger.info "Registering filters..."
			
			for path, injected of invoke 'filter'
				defaultLogger.info normalize path

				$filterProvider.register (normalize path), injected

			defaultLogger.info "Filters registered."

			# Invoke hook `service`.
			# Allows packages to define Angular services. Implementations
			# should return an [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation).
			defaultLogger.info "Registering services..."
			
			for path, injected of invoke 'service'
				defaultLogger.info path

				$provide.service path, injected
			
			defaultLogger.info "Services registered."

			# If we are testing, decorate the services with their mock
			# versions.
			if config.get 'testMode'
				
				# Invoke hook `serviceMock`.
				# Allows packages to decorate mock Angular services.
				# Implementations should return an
				# [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation).
				defaultLogger.info "Registering mock services..."
				
				for path, injected of invoke 'serviceMock'
					defaultLogger.info path

					$provide.decorator path, injected
			
				defaultLogger.info "Mock services registered."

	])

# A module that implements a package manager provider/service.
angular.module('shrub.pkgman', [
	'shrub.require'
])

	.provider 'pkgman', [
		'$provide', 'requireProvider'
		($provide, {require}) ->
			
			_ = require 'underscore'
			config = require 'config'
			pkgman = require 'pkgman'
			
			{defaultLogger} = require 'logging'
			
			# Load the package list from configuration.
			defaultLogger.info "Loading packages..."
			
			pkgman.registerPackageList config.get 'packageList'

			defaultLogger.info "Packages loaded."
			
			service = {}
			
			service.invoke = pkgman.invoke
			service.invokeFlat = pkgman.invokeFlat
			
			service.$get = -> service
			
			service
	]
