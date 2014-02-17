
angular.module('shrub.pkgman', [
	'shrub.require'
])

	.provider 'pkgman', [
		'$provide', 'configProvider', 'requireProvider'
		($provide, configProvider, requireProvider) ->
			
			require = requireProvider.require
			
			pkgman = require 'pkgman'
			
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

	.config [
		'$compileProvider', '$controllerProvider', '$filterProvider', '$provide', 'configProvider', 'pkgmanProvider', 'requireProvider'
		($compileProvider, $controllerProvider, $filterProvider, $provide, configProvider, pkgmanProvider, requireProvider) ->
			
			require = requireProvider.require
			
			i8n = require 'inflection'
			
			# Use camelized names for directives and filters:
			# 'core/foo/bar' -> 'coreFooBar'
			camelize = (path) ->
				i8n.camelize (path.replace '/', '_'), true
			
			pkgmanProvider.invoke 'controller', (path, spec) ->
				$controllerProvider.register path, spec

			pkgmanProvider.invoke 'directive', (path, spec) ->
				$compileProvider.directive (camelize path), spec

			pkgmanProvider.invoke 'filter', (path, spec) ->
				$filterProvider.register (camelize path), spec

			pkgmanProvider.invoke 'service', (path, spec, isMock) ->
				if isMock and 'e2e' is configProvider.get 'testMode'
					$provide.decorator path, spec
				else
					$provide.service path, spec
			
	]
	
	
