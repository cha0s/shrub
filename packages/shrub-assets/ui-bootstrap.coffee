
config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `assetScriptMiddleware`
	registrar.registerHook 'assetScriptMiddleware', ->
		
		label: 'UI Bootstrap'
		middleware: [
	
			(req, res, next) ->
				
				if 'production' is config.get 'NODE_ENV'
					
					res.locals.scripts.push '/lib/angular-ui/bootstrap/ui-bootstrap-tpls-0.10.0.min.js'
					
				else
					
					res.locals.scripts.push '/lib/angular-ui/bootstrap/ui-bootstrap-tpls-0.10.0.js'
					
				next()
				
		]
