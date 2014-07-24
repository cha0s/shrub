
config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `assetScriptMiddleware`
	registrar.registerHook 'assetScriptMiddleware', ->
		
		label: 'Angular'
		middleware: [
	
			(req, res, next) ->
				
				if 'production' is config.get 'NODE_ENV'
					
					res.locals.scripts.push '//ajax.googleapis.com/ajax/libs/angularjs/1.2.13/angular.min.js'
					res.locals.scripts.push '//ajax.googleapis.com/ajax/libs/angularjs/1.2.13/angular-route.min.js'						
					res.locals.scripts.push '//ajax.googleapis.com/ajax/libs/angularjs/1.2.13/angular-sanitize.min.js'						
					
				else
					
					res.locals.scripts.push '/lib/angular/angular.js'
					res.locals.scripts.push '/lib/angular/angular-route.js'
					res.locals.scripts.push '/lib/angular/angular-sanitize.js'
					
				next()
				
		]
