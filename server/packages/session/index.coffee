
express = require 'express'
winston = require 'winston'

exports.$httpMiddleware = (http) ->
	
	label: 'Load session from cookie'
	middleware: [
		http.cookieParser()
		express.session key: http.sessionKey(), store: http.sessionStore()
	]

exports.$socketMiddleware = (http) ->

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
