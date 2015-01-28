
# # Express routes

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `httpMiddleware`
	#
	# Serve Express routes.
	registrar.registerHook 'httpMiddleware', (http) ->

		label: 'Serve routes'
		middleware: [
			http._app.router
		]
