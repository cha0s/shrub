
angular.module('shrub.packages', [
	'shrub.require'
	'shrub.pkgman'
])

	.config([
		'$compileProvider', '$controllerProvider', '$filterProvider', '$provide', 'configProvider', 'pkgmanProvider', 'requireProvider'
		($compileProvider, $controllerProvider, $filterProvider, $provide, configProvider, pkgmanProvider, requireProvider) ->
			
			require = requireProvider.require
			
			i8n = require 'inflection'

			# Use normalized names for directives and filters:
			# 'core/foo/bar' -> 'coreFooBar'
			normalize = (path) ->
				parts = for part, i in path.split '/'
					i8n.camelize(
						part.replace /[^\w]/g, '_'
						0 is i
					)
					
				i8n.camelize (i8n.underscore parts.join ''), true

			for path, injected of pkgmanProvider.invokeWithMocks 'controller'
				$controllerProvider.register path, injected

			for path, injected of pkgmanProvider.invokeWithMocks 'directive'
				$compileProvider.directive (normalize path), injected

			for path, injected of pkgmanProvider.invokeWithMocks 'filter'
				$filterProvider.register (normalize path), injected

			for path, injected of pkgmanProvider.invoke 'service'
				$provide.service path, injected
			
			if configProvider.get 'testMode'
				for path, injected of pkgmanProvider.invoke 'serviceMock'
					$provide.decorator path, injected
			
	])

angular.module('shrub.pkgman', [
	'shrub.require'
])

	.provider 'pkgman', [
		'$provide', 'configProvider', 'requireProvider'
		($provide, configProvider, requireProvider) ->
			
			require = requireProvider.require
			
			_ = require 'underscore'
			pkgman = require 'pkgman'
			
			pkgman.registerPackages configProvider.get 'packageList'
			
			service = {}
			
			service.invoke = (hook, args...) ->
				
				args.unshift hook
				pkgman.invoke args...
				
			service.invokeFlat = (hook, args...) ->
				
				args.unshift hook
				pkgman.invokeFlat args...
				
			service.invokeWithMocks = (hook, args...) ->
				
				args.unshift hook
				results = @invoke args...
				
				if configProvider.get 'testMode'
					
					args[0] = "#{hook}Mock"
					_.extend results, pkgman.invoke args...
					
				results
				
			service.$get = -> service
			
			service
	]
