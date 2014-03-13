
exports.$auditKeys = (req) ->
	keys = []
	keys.push req.session.id if req.session?
	keys

exports.$socketMiddleware = ->

	label: 'Load session'
	middleware: [
	
		(req, res, next) ->
			
			return next() unless req and req.headers and req.headers.cookie
			
			req.http.loadSessionFromRequest(req).then(
				
				(session) ->
					
					req.session = session
					
					req.socket.join session.id
					
					next()
				
				(error) -> next error
			)
			
	]


	