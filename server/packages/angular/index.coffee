
contexts = require 'server/contexts'
jsdom = require('jsdom').jsdom
nconf = require 'nconf'
Q = require 'bluebird'
url = require 'url'
winston = require 'winston'

logger = new winston.Logger
	transports: [
		new winston.transports.Console level: 'silly', colorize: true
		new winston.transports.File level: 'debug', filename: 'logs/client.log'
	]

exports.$endpoint = ->
	
	route: 'hangup'
	receiver: (req, fn) ->
		
		return fn() unless req.session?
		return fn() unless (context = contexts.lookup req.session.id)?
		
		context.close fn

exports.$httpMiddleware = (http) ->
	
	newContext = (cookie, locals, fn) ->
		
		http.renderApp locals, (error, index) ->
			return fn error if error?
			
			# Hax: Fix document.domain since jsdom has a stub here.
			Object.defineProperties(
				(require 'jsdom/lib/jsdom/level2/html').dom.level2.html.HTMLDocument.prototype
				domain: get: -> 'localhost'
			)
			
			# Set up a DOM, forwarding our cookie and navigating to the entry
			# point.
			document = jsdom(
				index, jsdom.defaultLevel
				
				cookie: cookie
				cookieDomain: 'localhost'
				url: "http://localhost:#{http.port()}/shrub-entry-point"
			)
			
			context = window: window = document.createWindow()
			
			# Capture "client" console logs.
			window.console =
				info: logger.info.bind logger
				log: logger.info.bind logger
				debug: logger.debug.bind logger
				warn: logger.warn.bind logger
				error: logger.error.bind logger
			
			# Hack in WebSocket.
			window.WebSocket = require 'socket.io/node_modules/socket.io-client/node_modules/ws/lib/WebSocket'
			
			window.onload = ->
				
				# Catch any errors in the client.
				for error in window.document.errors
					if error.data?.error?
						return fn error.data.error
				
				# Inject Angular services so we can get up in its guts.
				shrub = context.shrub = {}
				injected = [
					'$location', '$rootScope', '$route', '$sniffer'
					'form', 'socket'
				]
				invocation = injected.concat [
					-> shrub[inject] = arguments[i] for inject, i in injected
				]
				injector = window.angular.element(window.document).injector()
				injector.invoke invocation
				
				# Don't even try HTML 5 history on the server side.
				shrub['$sniffer'].history = false
				
				# Let the socket finish initialization.						
				shrub.socket.on 'initialized', ->
					process.nextTick -> fn null, context
				
	angularContext = (id, cookie, locals, fn) ->
		
		# Already exists?
		return fn null, context if (context = contexts.lookup id)?
		
		# Create one otherwise.
		newContext cookie, locals, (error, context) ->
			return fn error if error?
			fn null, contexts.add id, context
		
	navigate = (context, path, body, fn) ->
		
		{shrub, window} = context
		{$location, $rootScope} = shrub
		
		originalUrl = $location.url()
		
		# Process any forms.
		formFn = ->
			return fn() unless body.formKey?
			return fn() unless (formSpec = shrub.form.lookup body.formKey)?
			
			scope = formSpec.scope
			form = scope[body.formKey]
			
			for named in formSpec.element.find '[name]'
				continue unless (value = body[named.name])?
				scope[named.name] = value
				
			# Submit handlers return promises.
			scope.$apply -> form.submit.handler().finally ->
				
				# Catch any path changes.
				if path isnt $location.url()
					if redirect = context.pathRedirect $location.url()
						context.redirect = redirect
					else
						context.redirect = $location.url()
					
				fn()
			
		# If the path has changed, navigate Angular to it.			
		if path isnt url.parse(window.location.href).path
			
			unlisten = $rootScope.$on 'shrubFinishedRendering', ->
				unlisten()
				
				# Catch any path changes.
				if path isnt $location.url()
					if redirect = context.pathRedirect $location.url()
						context.redirect = redirect
					else
						context.redirect = $location.url()
					
				formFn()
				
			$rootScope.$apply -> $location.path path
		
		# Otherwise, we're already there.
		else
			formFn()
		
	label: 'Render page with Angular'
	middleware: [
	
		(req, res, next) ->
			
			{path} = url.parse req.url
			
			id = req.session.id
			locals = res.locals
			body = req.body
			
			# Skip render in a local context?
			unless nconf.get 'contexts:render'
				return http.renderApp locals, (error, index) -> res.end index
			
			extractCookie = (fn) ->
				
				# If the client is in sync, awesome!
				if req.signedCookies[http.sessionKey()] is req.sessionID
					
					fn req.headers.cookie
					
				# Otherwise, stimulate the session middleware to create the cookie.
				else
					res.emit 'header'
					
					# Yank it out of the response headers and map it.
					setCookie = res._headers['set-cookie']
					cookieObject = {}
					for kv in setCookie.split ';'
						[key, value] = kv.split '='
						cookieObject[key.trim()] = value
					
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
					req.session.save -> fn cookie
				
			extractCookie (cookie) ->
				
				# Get a DOM window.
				angularContext id, cookie, locals, (error, context) ->
					
					return next new Error error.stack if error?
					
					{shrub, window} = context
					
					# Touch the context to keep it alive.
					context.touch()
					
					# Emit the last HTML generated before the redirect.
					if context.redirect
						return process.nextTick ->
							res.end context.redirect
							context.redirect = null
					
					# Handle redirection.
					if redirect = context.pathRedirect path
						return res.redirect redirect
					
					# Prevent a possible race condition that would hang up the
					# context in between now and render.
					deferred = Q.defer()
					context.promise = deferred.promise
					
					# Navigate the Angular system to the new path.
					navigate context, path, body, (delay) ->
						
						# Reload the session, server-side JS socket stuff could
						# have changed it!
						req.session.reload ->
							
							# Don't forget the doctype!
							emission = """
<!doctype html>
#{window.document.innerHTML}
"""
							
							# If a redirect happened on the context, actually
							# redirect the browser and save the emission for
							# the next request.
							if context.redirect
								res.redirect context.redirect
								context.redirect = emission
							
							# Otherwise, just emit.	
							else
								
								# Emit.
								res.end emission
							
							# Let any context expirations take place now that
							# we've emitted.
							deferred.resolve()
							context.promise = null

	]
