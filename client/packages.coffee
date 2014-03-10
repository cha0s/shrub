
angular.module('shrub.pkgman', [
	'shrub.require'
])

	.provider 'pkgman', [
		'$provide', 'configProvider', 'requireProvider'
		($provide, configProvider, requireProvider) ->
			
			require = requireProvider.require
			
			pkgman = require 'pkgman'
			
			pkgman.registerPackages configProvider.get 'packageList'
			
			service = {}
			
			service.invoke = (hook, fn) ->
				
				pkgman.invoke hook, (path, spec) -> fn path, spec, false
				
				if configProvider.get 'testMode'
					pkgman.invoke "#{hook}Mock", (path, spec) ->
						fn path, spec, true

			service.undoMock = (hook, path) ->
				
				pkgman.invoke hook, (_path_, spec) ->
					$provide.decorator path, spec if path is _path_ 
				
			service.$get = -> service
			
			service
	]

angular.module('shrub.packages', [
	'shrub.require'
	'shrub.pkgman'
])

	.config([
		'$compileProvider', '$controllerProvider', '$filterProvider', '$provide', 'pkgmanProvider', 'requireProvider'
		($compileProvider, $controllerProvider, $filterProvider, $provide, pkgmanProvider, requireProvider) ->
			
			require = requireProvider.require
			
			i8n = require 'inflection'

			# Use normalize names for directives and filters:
			# 'core/foo/bar' -> 'coreFooBar'
			normalize = (path) ->
				parts = for part, i in path.split '/'
					i8n.camelize(
						part.replace /[^\w]/g, '_'
						0 is i
					)
					
				i8n.camelize (i8n.underscore parts.join ''), true

			pkgmanProvider.invoke 'controller', (path, spec) ->
				$controllerProvider.register path, spec

			pkgmanProvider.invoke 'directive', (path, spec) ->
				$compileProvider.directive (normalize path), spec

			pkgmanProvider.invoke 'filter', (path, spec) ->
				$filterProvider.register (normalize path), spec

			pkgmanProvider.invoke 'service', (path, spec, isMock) ->
				if isMock
					$provide.decorator path, spec
				else
					$provide.service path, spec
			
	])
