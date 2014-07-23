
# # Assets
# 
# Serve different JS based on whether the server is running in production mode.

_ = require 'underscore'
config = require 'config'
pkgman = require 'pkgman'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `httpMiddleware`
	registrar.registerHook 'httpMiddleware', (http) ->
		
		label: 'Serve dynamic assets'
		middleware: [
	
			(req, res, next) ->
				
				res.locals.assets =
				
					js: if 'production' is config.get 'NODE_ENV'
						
	
						[
							'//code.jquery.com/jquery-1.11.0.min.js'
	
							'/lib/bootstrap/js/bootstrap.min.js'
							
							'/lib/socket.io/socket.io.min.js'
							
							'/before-angular.js'
	
							'//ajax.googleapis.com/ajax/libs/angularjs/1.2.13/angular.min.js'
							'//ajax.googleapis.com/ajax/libs/angularjs/1.2.13/angular-route.min.js'						
							'//ajax.googleapis.com/ajax/libs/angularjs/1.2.13/angular-sanitize.min.js'						
	
							'/lib/angular-ui/bootstrap/ui-bootstrap-tpls-0.10.0.min.js'
							
							'/shrub.min.js'
	
							'/js/config.js'
						]
			
					else
						
						[
							'/lib/jquery/jquery-1.11.0.js'
							
							'/lib/bootstrap/js/bootstrap.js'
			
							'/lib/socket.io/socket.io.js'
							
							'/before-angular.js'
							
							'/lib/angular/angular.js'
							'/lib/angular/angular-route.js'
							'/lib/angular/angular-sanitize.js'
	
							'/lib/angular-ui/bootstrap/ui-bootstrap-tpls-0.10.0.js'
							
							'/shrub.js'
							
							'/js/config.js'
						]
						
				next()
		
		]
