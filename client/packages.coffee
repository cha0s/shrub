
# A module that allows packages to provide Angular components.
angular.module('shrub.packages', [
	'shrub.require'
	'shrub.pkgman'
])

	.config([
		'$compileProvider', '$controllerProvider', '$filterProvider', '$provide', 'configProvider', 'pkgmanProvider', 'requireProvider'
		($compileProvider, $controllerProvider, $filterProvider, $provide, configProvider, {invoke}, {require}) ->
			
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
			for path, injected of invoke 'controller'
				$controllerProvider.register path, injected

			# Invoke hook `directive`.
			# Allows packages to define Angular directives. Implementations
			# should return an [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation).
			for path, injected of invoke 'directive'
				$compileProvider.directive (normalize path), injected

			# Invoke hook `filter`.
			# Allows packages to define Angular filters. Implementations
			# should return a function.
			for path, injected of invoke 'filter'
				$filterProvider.register (normalize path), injected

			# Invoke hook `service`.
			# Allows packages to define Angular services. Implementations
			# should return an [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation).
			for path, injected of invoke 'service'
				$provide.service path, injected
			
			# If we are testing, decorate the services with their mock
			# versions.
			if configProvider.get 'testMode'
				
				# Invoke hook `serviceMock`.
				# Allows packages to decorate mock Angular services.
				# Implementations should return an
				# [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation).
				for path, injected of invoke 'serviceMock'
					$provide.decorator path, injected
			
	])

# A module that implements a package manager provider/service.
angular.module('shrub.pkgman', [
	'shrub.require'
])

	.provider 'pkgman', [
		'$provide', 'configProvider', 'requireProvider'
		($provide, configProvider, {require}) ->
			
			_ = require 'underscore'
			pkgman = require 'pkgman'
			
			# Load the package list from configuration.
			pkgman.registerPackages configProvider.get 'packageList'
			
			service = {}
			
			service.invoke = pkgman.invoke
			service.invokeFlat = pkgman.invokeFlat
			
			service.$get = -> service
			
			service
	]
