
config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `httpMiddleware`
	registrar.registerHook 'httpMiddleware', (http) ->

		label: 'Skin path handling'
		middleware: [
			
			(req, res, next) ->
				
				# If we get here and it's a skin URL, it must be a 404
				# otherwise, express/static would have picked it up already.
				return res.send 404 if req.path.match /^\/skin\//
					
				next()
		]
