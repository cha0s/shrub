
# A module that allows packages to provide Angular components.
angular.module('shrub.packages', [
	'shrub.require'
	'shrub.pkgman'
])

	.config([
		'$compileProvider', '$controllerProvider', '$filterProvider', '$injector', '$provide', 'shrub-pkgmanProvider', 'shrub-requireProvider'
		($compileProvider, $controllerProvider, $filterProvider, $injector, $provide, pkgman, {require}) ->
			
			_ = require 'underscore'
			
			config = require 'config'
			debug = require('debug') 'shrub:angular'
			skin = require 'skin'
			
			# Invoke hook `controller`.
			# Allows packages to define Angular controllers. Implementations
			# should return an [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation).
			debug "Registering controllers..."
			
			for path, injected of pkgman.invoke 'controller'
				debug path
				
				$controllerProvider.register path, injected

			debug "Controllers registered."

			# Invoke hook `directive`.
			# Allows packages to define Angular directives. Implementations
			# should return an [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation).
			debug "Registering directives..."
			
			for path, injected of pkgman.invoke 'directive'
				do (path, injected) ->
					name = pkgman.normalizePath path
					
					debug name
					
					$compileProvider.directive name, injected
					
					$provide.factory "#{name}Directive", [
						'$injector'
						($injector) ->
						
							directive = $injector.invoke injected
								
							# Normalize directive.	
							if angular.isFunction directive
								directive = compile: -> directive
							else if not directive.compile and directive.link
								directive.compile = -> directive.link
							directive.priority ?= 0
							directive.index = 0
							directive.name ?= name
							directive.require ?= directive.controller and directive.name
							directive.restrict ?= 'A'
							
							# Invoke hook `augmentDirective`.
							# Allows packages to augment the directives
							# defined by packages. One example is the automatic
							# relinking functionality implemented by [shrub-skin](/packages/shrub-skin/client/index.html#implementshookaugmentdirective).
							for injectedDirective in pkgman.invokeFlat(
								'augmentDirective', directive, path
							)
								$injector.invoke injectedDirective
							
							[directive]
			
					]
						
			debug "Directives registered."

			# Invoke hook `filter`.
			# Allows packages to define Angular filters. Implementations
			# should return a function.
			debug "Registering filters..."
			
			for path, injected of pkgman.invoke 'filter'
				name = pkgman.normalizePath path
				
				debug name

				$filterProvider.register name, injected

			debug "Filters registered."

			# Invoke hook `provider`.
			# Allows packages to define Angular providers. Implementations
			# should return an [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation).
			debug "Registering providers..."
			
			for path, provider of pkgman.invoke 'provider'
				debug path

				$provide.provider path, provider
			
			debug "Providers registered."

			# Invoke hook `service`.
			# Allows packages to define Angular services. Implementations
			# should return an [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation).
			debug "Registering services..."
			
			for path, injected of pkgman.invoke 'service'
				debug path

				$provide.service path, injected
			
			debug "Services registered."

			# If we are testing, decorate the services with their mock
			# versions.
			if config.get 'packageConfig:shrub-core:testMode'
				
				# Invoke hook `serviceMock`.
				# Allows packages to decorate mock Angular services.
				# Implementations should return an
				# [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation).
				debug "Registering mock services..."
				
				for path, injected of pkgman.invoke 'serviceMock'
					debug path

					$provide.decorator path, injected
			
				debug "Mock services registered."

	])

# A module that implements a package manager provider/service.
angular.module('shrub.pkgman', [
	'shrub.require'
])

	.provider 'shrub-pkgman', [
		'$provide', 'shrub-requireProvider'
		($provide, {require}) ->
			
			_ = require 'underscore'
			config = require 'config'
			debug = require('debug') 'shrub:pkgman'
			pkgman = require 'pkgman'
			
			# Load the package list from configuration.
			debug "Loading packages..."
			
			pkgman.registerPackageList config.get 'packageList'

			debug "Packages loaded."
			
			service = {}
			
			service.invoke = pkgman.invoke
			service.invokeFlat = pkgman.invokeFlat
			
			# Use normalized names for directives and filters:
			# 'core/foo/bar' -> 'coreFooBar'
			i8n = require 'inflection'
			service.normalizePath = (path) ->
				parts = for part, i in path.split '/'
					i8n.camelize(
						part.replace /[^\w]/g, '_'
						0 is i
					)
					
				i8n.camelize (i8n.underscore parts.join ''), true

			service.$get = -> service
			
			service
	]
