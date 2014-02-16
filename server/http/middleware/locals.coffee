
nconf = require 'nconf'

module.exports.middleware = (http) ->
	
	(req, res, next) ->
		
		config =
			debugging: 'production' isnt req.app.get 'env'
		
		res.locals.configJson = JSON.stringify config
		
		res.locals.assets =
		
			js: if 'production' is nconf.get 'NODE_ENV'
				
				[
					'/lib/underscore/underscore-min.js'
	
					'//code.jquery.com/jquery-1.9.1.min.js'
					
					'/lib/bootstrap/js/bootstrap.min.js'
					
					'/lib/socket.io/socket.io.min.js'
					
					'/js/before-angular.js'
				
					'//ajax.googleapis.com/ajax/libs/angularjs/1.0.4/angular.min.js'
					'//ajax.googleapis.com/ajax/libs/angularjs/1.0.4/angular-sanitize.min.js'
					'/lib/angular-strap/angular-strap.min.js'
					'/js/angular.min.js'
					
					'/js/modules.min.js'
				]
	
			else
				
				[
					'/lib/underscore/underscore.js'
					
					'/lib/jquery/jquery-1.9.js'
	
					'/lib/bootstrap/js/bootstrap.js'
			
					'/lib/socket.io/socket.io.js'
					
					'/js/before-angular.js'
					
					'/lib/angular/angular.js'
					'/lib/angular/angular-route.js'
					'/lib/angular/angular-sanitize.js'
					'/lib/angular-strap/angular-strap.js'
					'/js/app.js'
					
					'/js/modules.js'
					
					if process.env['E2E']
						'/js/mocks.js'
					else
						'/js/empty-mocks.js'
					
				]
				
		
		next()
