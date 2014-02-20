
exports.$httpMiddleware = (http) ->
	
	app = http._app
	
	label: 'Serve routes'
	middleware: [

		app.router
		
	]
