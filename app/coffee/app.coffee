'use strict'

angular.module('Shrub', [
	'ngRoute'
	'ngSanitize'
	
	'shrub.controllers'
	'shrub.filters'
	'shrub.services'
	'shrub.directives'
	'shrub.mocks'
	'shrub.packages'
	
	'shrub.require'
	
	'$strap.directives'
]).

	config([
		'$routeProvider', '$locationProvider', '$interpolateProvider', 'mockRouteProvider', 'requireProvider'
		($routeProvider, $locationProvider, $interpolateProvider, mockRouteProvider, requireProvider) ->
			
# Set up package routes.
			pkgman = requireProvider.require 'pkgman'
			pkgman.invoke 'route', (path, route) ->

				routeController = route.controller
				route.controller = [
					'$injector', '$scope', 'title'
					($injector, $scope, title) ->
						
						title.setPage route.title if route.title?
						
						$injector.invoke(
							routeController, null
							$scope: $scope
						)
					
				]
				
				$routeProvider.when "/#{route.path ? path}", route
			
# Create a unique entry point.
			$routeProvider.when '/shrub-entry-point', {}
			
# Mock routes for testing, in development or production mode, this will be
# empty.
			mockRouteProvider.when $routeProvider
			
			$routeProvider.otherwise redirectTo: '/home'
			
			$locationProvider.html5Mode true
	])
	
# Application initialization.
	.run([
		'nav', 'title'
		(nav, title) ->
			
			title.setSite 'Shrub'
			
			nav.setLinks [
				pattern: '/home', href: '/home', name: 'Home'
			,
				pattern: '/about', href: '/about', name: 'About'
			,
				pattern: '/user/register', href: '/user/register', name: 'Sign up'
			,
				pattern: '/user/login', href: '/user/login', name: 'Sign in'
			,
				pattern: '/user/logout', href: '/user/logout', name: 'Sign out'
			]
	])
