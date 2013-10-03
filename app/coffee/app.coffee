'use strict'

angular.module('Shrub', [
	'ngRoute'
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
		
# Set up our routes.
			$routeProvider.when '/home', templateUrl: '/partials/home.html', controller: 'HomeCtrl'
			$routeProvider.when '/about', templateUrl: '/partials/about.html', controller: 'AboutCtrl'

# Create a unique entry point.
			$routeProvider.when '/shrub-entry-point', {}
			
# Mock routes for testing, in development or production mode, this will be
# empty.
			mockRouteProvider.when $routeProvider
			
			$routeProvider.otherwise redirectTo: '/home'
			
			$locationProvider.html5Mode true
	])
	
# Looks like we're injecting a lot of unnecessary stuff, doesn't it? However
# by doing this, we are making sure that each of these is injected as soon as
# the application runs. This is desirable for many things.
	.run([
		'$injector', '$window', 'config', 'nav', 'notifications', 'socket', 'title', 'window'
		($injector, $window, config, nav, notifications, socket, title, window) ->
			
			$window.shrubInjector? $injector
			
			title.setSite 'Shrub'
			
			socket.on 'initialized', ->
				
				socket.emit 'session.id'
			
			nav.setLinks [
				pattern: '/home', href: '/home', name: 'Home'
			,
				pattern: '/about', href: '/about', name: 'About'
			]
	])
