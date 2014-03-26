
# # Session
# 
# Various means for dealing with sessions.

# ## Implements hook `fingerprint`
exports.$fingerprint = (req) ->
	
	# Session ID.
	session: if req?.session? then req.session.id

# ## Implements hook `socketAuthorizationMiddleware`
exports.$socketAuthorizationMiddleware = ->

	label: 'Load session'
	middleware: [
	
		(req, res, next) ->
			
			req.http.loadSessionFromRequest(
				req
			
			).then((session) ->
				req.session = session
				next()
				
			).catch next
			
	]

# ## Implements hook `socketConnectionMiddleware`
exports.$socketConnectionMiddleware = ->

	label: 'Join channel for socket'
	middleware: [
	
		(req, res, next) ->
			
			req.socket.join session.id if session?
				
			next()
			
	]
