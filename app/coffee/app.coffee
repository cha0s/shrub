'use strict'

angular.module('Shrub', [
	'ngSanitize'
	
	'Shrub.controllers'
	'Shrub.filters'
	'Shrub.services'
	'Shrub.directives'
	'Shrub.mocks'
	
	'Shrub.require'
	
	'$strap.directives'
]).

	config([
		'$routeProvider', '$locationProvider', '$interpolateProvider', 'mockRouteProvider'
		($routeProvider, $locationProvider, $interpolateProvider, mockRouteProvider) ->
		
# We want to be able to do server-side rewrites with Handlebars,
# and that presents a conflict.
			$interpolateProvider.startSymbol '{['
			$interpolateProvider.endSymbol ']}'
			
# Set up our routes.
			$routeProvider.when '/home', templateUrl: '/partials/home.html', controller: 'HomeCtrl'
			$routeProvider.when '/about', templateUrl: '/partials/about.html', controller: 'AboutCtrl'
			$routeProvider.otherwise redirectTo: '/home'
			
# Mock routes for testing, in development or production mode, this will be
# empty.
			mockRouteProvider.test $routeProvider
			
#			$locationProvider.html5Mode true
	])
	
# Looks like we're injecting a lot of unnecessary stuff, doesn't it? However
# by doing this, we are making sure that each of these is injected as soon as
# the application runs. This is desirable for many things.
	.run([
		'$location', '$rootScope', '$window', 'config', 'nav', 'notifications', 'socket', 'title', 'window'
		($location, $rootScope, $window, config, nav, notifications, socket, title, window) ->
			
			title.setSite 'Shrub'

			nav.setLinks [
				pattern: '/home', href: '#/home', name: 'Home'
			,
				pattern: '/about', href: '#/about', name: 'About'
			]
	])
