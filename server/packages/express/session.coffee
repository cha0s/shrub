
express = require 'express'

exports.$httpMiddleware = (http) ->
	
	label: 'Load session from cookie'
	middleware: [
		http.cookieParser()
		express.session key: http.sessionKey(), store: http.sessionStore()
	]
