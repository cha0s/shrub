
config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `assetScriptMiddleware`
	registrar.registerHook 'assetScriptMiddleware', ->
		
		label: 'jQuery'
		middleware: [
	
			(req, res, next) ->
				
				if 'production' is config.get 'NODE_ENV'
					
					res.locals.scripts.push '//code.jquery.com/jquery-1.11.0.min.js'
					
				else
					
					res.locals.scripts.push '/lib/jquery/jquery-1.11.0.js'
				
				next()
				
		]
