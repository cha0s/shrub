
# # Session
# 
# Various means for dealing with sessions.

Promise = require 'bluebird'
signature = require 'cookie-signature'

config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `fingerprint`
	registrar.registerHook 'fingerprint', (req) ->
		
		# Session ID.
		session: if req?.session? then req.session.id
	
	# ## Implements hook `endpointFinished`
	registrar.registerHook 'endpointFinished', (routeReq, result, req) ->
		return unless routeReq.session?
		
		# Touch and save the session after every RPC call finishes.
		deferred = Promise.defer()
		routeReq.session.touch().save deferred.callback
		
		# Propagate changes back up to the original request.
		deferred.promise.then -> req.session = routeReq.session
	
	# ## Implements hook `httpMiddleware`
	# 
	# Normalize the cookie.
	registrar.registerHook 'httpMiddleware', (http) ->
		
		label: 'Normalize request cookie'
		middleware: [
			
			# If this is the first request made by a client, the cookie won't exist
			# in req.headers.cookie. We normalize that inconsistency, so all
			# consumers of the cookie will have a consistent interface on the first
			# as well as subsequent requests.
			(req, res, next) ->
				
				{cookie, key} = config.get 'packageSettings:shrub-session'
				
				# } If the client is in sync, awesome!
				return next() if req.signedCookies[key] is req.sessionID
				
				# } Generate the cookie
				val = "s:" + signature.sign req.sessionID, cookie.cryptoKey
				cookie = req.session.cookie.serialize key, val
				
				cookieObject = {}
				for kv in cookie.split ';'
					[k, v] = kv.split '='
					cookieObject[k.trim()] = v
				
				# } Pull out junk that only makes sense en route to client.
				delete cookieObject['Path']
				delete cookieObject['HttpOnly']
				
				# } Rebuild the cookie string.
				cookie = ''
				for k, v of cookieObject
					cookie += '; ' if cookie
					cookie += k + '=' + v
					
				# } Commit the session before offering the cookie, otherwise it
				# } wouldn't actually be pointing at anything yet.
				req.session.save (error) ->
					next error if error?
					
					req.signedCookies[key] = req.sessionID
					req.headers.cookie = cookie
					next()
		
		]
	
	# ## Implements hook `packageSettings`
	registrar.registerHook 'packageSettings', ->
		
		# Session store instance.
		sessionStore: 'redis'
		
		# Key within the cookie where the session is stored.
		key: 'connect.sid'
		
		# Cookie information.
		cookie:
			
			# The crypto key we encrypt the cookie with.
			cryptoKey: '***CHANGE THIS***'
			
			# The max age of this session. Defaults to two weeks.
			maxAge: 1000 * 60 * 60 * 24 * 14
	
	# ## Implements hook `socketConnectionMiddleware`
	registrar.registerHook 'socketConnectionMiddleware', ->
	
		label: 'Join channel for session'
		middleware: [
		
			(req, res, next) ->
				
				return req.socket.join session.id, next if session?
					
				next()
				
		]
		
	registrar.recur [
		'express'
	]
