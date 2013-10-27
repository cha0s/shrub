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
		'$routeProvider', '$locationProvider', '$interpolateProvider', 'mockRouteProvider'
		($routeProvider, $locationProvider, $interpolateProvider, mockRouteProvider) ->
		
# Set up our routes.
			$routeProvider.when '/home', templateUrl: '/partials/home.html', controller: 'home'
			$routeProvider.when '/about', templateUrl: '/partials/about.html', controller: 'about'
			
			$routeProvider.when '/user/login', templateUrl: '/partials/user/login.html', controller: 'user/login'
			$routeProvider.when '/user/logout', template: '-', controller: 'user/logout'

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
				pattern: '/user/login', href: '/user/login', name: 'Sign in'
			,
				pattern: '/user/logout', href: '/user/logout', name: 'Sign out'
			]
	])
