
# # Session
# 
# Various means for dealing with sessions.

Promise = require 'bluebird'

# ## Implements hook `fingerprint`
exports.$fingerprint = (req) ->
	
	# Session ID.
	session: if req?.session? then req.session.id

# ## Implements hook `endpointFinished`
exports.$endpointFinished = (req, result) ->
	
	return Promise.resolve() unless req.session?
	
	# Touch and save the session after every RPC call finishes.
	deferred = Promise.defer()
	req.session.touch().save deferred.callback
	deferred.promise 

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
