
_ = require 'underscore'
nconf = require 'nconf'
pkgman = require 'pkgman'

exports.$httpMiddleware = (http) ->
	
	label: 'Serve dynamic assets'
	middleware: [

		(req, res, next) ->
			
			res.locals.assets =
			
				js: if 'production' is nconf.get 'NODE_ENV'
					
					[
						'/lib/underscore/underscore-min.js'
		
						'//code.jquery.com/jquery-1.9.1.min.js'
						
						'/lib/bootstrap/js/bootstrap.min.js'
						
						'/lib/socket.io/socket.io.min.js'
						
						'//ajax.googleapis.com/ajax/libs/angularjs/1.0.4/angular.min.js'
						'//ajax.googleapis.com/ajax/libs/angularjs/1.0.4/angular-sanitize.min.js'
						'/lib/angular-strap/angular-strap.min.js'
						
						'/shrub.min.js'
						
						'/js/config.js'
					]
		
				else
					
					[
						'/lib/underscore/underscore.js'
						
						'/lib/jquery/jquery-1.9.js'
		
						'/lib/bootstrap/js/bootstrap.js'
				
						'/lib/socket.io/socket.io.js'
						
						'/lib/angular/angular.js'
						'/lib/angular/angular-route.js'
						'/lib/angular/angular-sanitize.js'
						'/lib/angular-strap/angular-strap.js'
						
						'/shrub.js'
						
						'/js/config.js'
					]
					
			next()
	
	]
