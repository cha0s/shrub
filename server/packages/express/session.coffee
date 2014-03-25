
express = require 'express'
signature = require 'express/node_modules/cookie-signature'

exports.$httpMiddleware = (http) ->
	
	label: 'Load session from cookie'
	middleware: [
		http.cookieParser()
		express.session key: http.sessionKey(), store: http.sessionStore()
		
# If this is the first request made by a client, the cookie won't exist in
# req.headers.cookie. We normalize that inconsistency, so all consumers of the
# cookie will have a consistent interface on the first as well as subsequent
# requests.
		
		(req, res, next) ->
			
			key = http.sessionKey()
			
			# If the client is in sync, awesome!
			return next() if req.signedCookies[key] is req.sessionID
			
			# Generate the cookie
			val = "s:" + signature.sign req.sessionID, http.cookieSecret()
			cookie = req.session.cookie.serialize key, val
			
			cookieObject = {}
			for kv in cookie.split ';'
				[k, v] = kv.split '='
				cookieObject[k.trim()] = v
			
			# Pull out junk that only makes sense en route to client.
			delete cookieObject['Path']
			delete cookieObject['HttpOnly']
			
			# Rebuild the cookie string.
			cookie = ''
			for k, v of cookieObject
				cookie += '; ' if cookie
				cookie += k + '=' + v
				
			# Commit the session before offering the cookie, otherwise it
			# wouldn't actually be pointing at anything yet.
			req.session.save (error) ->
				next error if error?
				
				req.signedCookies[key] = req.sessionID
				req.headers.cookie = cookie
				next()
	
	]
