
angular.module('shrub.pkgman', [
	'shrub.require'
])

	.provider 'pkgman', [
		'configProvider', 'requireProvider'
		(configProvider, requireProvider) ->
			
			pkgman = requireProvider.require 'pkgman'
			
			invokeWithMocks = (hook, fn) ->
				
				results = {}
				
				pkgman.invoke hook, (path, spec) -> results[path] = spec
				
				if configProvider.get 'useMocks'
					pkgman.invoke "#{hook}Mock", (path, spec) -> results[path] = spec
				
				fn path, spec for path, spec of results
			
			invoke: invokeWithMocks
			$get: -> invoke: invokeWithMocks
	]

angular.module('shrub.packages', [
	'shrub.require'
	'shrub.pkgman'
])

	.config [
		'$compileProvider', '$controllerProvider', '$filterProvider', '$provide', 'pkgmanProvider', 'requireProvider'
		($compileProvider, $controllerProvider, $filterProvider, $provide, pkgmanProvider, requireProvider) ->
			
			require = requireProvider.require
			
			_ = require 'underscore'
			i8n = require 'inflection'
			
			# Use camelized names for directives and filters:
			# 'core/foo/bar' -> 'coreFooBar'
			camelize = (path) -> i8n.camelize (path.replace '/', '_'), true
			
			pkgmanProvider.invoke 'controller', (path, spec) ->
				$controllerProvider.register path, spec
			
			pkgmanProvider.invoke 'directive', (path, spec) ->
				$compileProvider.directive (camelize path), spec
			
			pkgmanProvider.invoke 'filter', (path, spec) ->
				$filterProvider.register (camelize path), spec
			
			pkgmanProvider.invoke 'service', (path, spec) ->
				$provide.service path, spec
			
	]
	
	
