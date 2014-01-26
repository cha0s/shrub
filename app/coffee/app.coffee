'use strict'

angular.module('Shrub', [
	'ngRoute'
	'ngSanitize'
	
	'shrub.controllers'
	'shrub.filters'
	'shrub.services'
	'shrub.directives'
	'shrub.mocks'
	
	'shrub.require'
	
	'$strap.directives'
]).

	config([
		'$routeProvider', '$locationProvider', '$interpolateProvider', 'mockRouteProvider', 'requireProvider'
		($routeProvider, $locationProvider, $interpolateProvider, mockRouteProvider, requireProvider) ->
			
# Set up our routes.
			$routeProvider.when '/home', templateUrl: '/partials/home.html', controller: 'home'
			$routeProvider.when '/about', templateUrl: '/partials/about.html', controller: 'about'
			
			requireProvider.require('packageManager').loadRoutes (
				(path, packageKey, route) ->

					if route.params?
						path += "/:#{route.params.join '/:'}"
					
					routeController = route.controller
					route.controller = [
						'$injector', '$scope', 'title'
						($injector, $scope, title) ->
							
							title.setPage route.title ? ''
							
							$injector.invoke(
								routeController
								null
								$scope: $scope
							)
						
					]
					
					$routeProvider.when "/#{path}", route
			)
			
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
