
config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `assetMiddleware`
	registrar.registerHook 'assetMiddleware', ->
		
		label: 'jQuery'
		middleware: [
	
			(assets, next) ->
				
				if 'production' is config.get 'NODE_ENV'
					
					assets.scripts.push '//code.jquery.com/jquery-1.11.0.min.js'
					
				else
					
					assets.scripts.push '/lib/jquery/jquery-1.11.0.js'
				
				next()
				
		]
