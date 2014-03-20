
exports.$auditKeys = (req) ->
	
	session: req.session.id if req.session?

exports.$socketAuthorizationMiddleware = ->

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


exports.$socketRequestMiddleware = ->

	label: 'Join channel for socket'
	middleware: [
	
		(req, res, next) ->
			
			req.socket.join session.id if session?
				
			next()
			
	]
