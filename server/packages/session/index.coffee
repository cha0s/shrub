
exports.$socketMiddleware = ->

	label: 'Load session'
	middleware: [
	
		(req, res, next) ->
			
			return next() unless req and req.headers and req.headers.cookie
			
			req.http.loadSessionFromRequest(req).then(
				
				(session) ->
					
					req.session = session
					next()
				
				(error) -> next error
			)
			
	]


	