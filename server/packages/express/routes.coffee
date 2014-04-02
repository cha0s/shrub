
# # Express routes

# ## Implements hook `httpMiddleware`
# 
# Serve Express routes.
exports.$httpMiddleware = (http) ->
	
	label: 'Serve routes'
	middleware: [
		http._app.router
	]
