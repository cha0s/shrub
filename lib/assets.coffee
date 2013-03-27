
module.exports = (app) ->

	app.configure 'development', ->
		
		angularUrls = [
			'/lib/angular/angular.js'
			'/lib/angular/angular-sanitize.js'
			'/lib/angular-strap/angular-strap.js'
			'/js/app.js'
			'/js/services.js'
			'/js/controllers.js'
			'/js/filters.js'
			'/js/directives.js'
		]
		
		if process.env['E2E']
			
			angularUrls.push '/js/mocks.js'
			
		else
		
			angularUrls.push '/js/empty-mocks.js'
			
		app.locals
			
			socketIoUrl: '/lib/socket.io/socket.io.js'
			
			underscoreUrl: '/lib/underscore/underscore.js'
			
			modulesUrl: '/js/modules.js'
			
			angularUrls: angularUrls
			
			jQueryUrls: [
				'/lib/jquery/jquery-1.9.js'
			]
		
	app.configure 'production', ->
		
		app.locals
			
			socketIoUrl: '/lib/socket.io/socket.io.min.js'
			
			underscoreUrl: '/lib/underscore/underscore-min.js'

			modulesUrl: '/js/modules.min.js'
			
			angularUrls: [
				'//ajax.googleapis.com/ajax/libs/angularjs/1.0.4/angular.min.js'
				'//ajax.googleapis.com/ajax/libs/angularjs/1.0.4/angular-sanitize.min.js'
				'/lib/angular-strap/angular-strap.min.js'
				'/js/angular.min.js'
			]
			
			jQueryUrls: [
				'//code.jquery.com/jquery-1.9.1.min.js'
			]
