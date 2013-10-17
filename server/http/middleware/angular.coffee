
_ = require 'underscore'
jsdom = require('jsdom').jsdom
nconf = require 'nconf'
Q = require 'q'
url = require 'url'
winston = require 'winston'

logger = new winston.Logger
	transports: [
		new winston.transports.Console level: 'error', colorize: true
		new winston.transports.File level: 'debug', filename: 'logs/client.log'
	]

module.exports.middleware = (http) ->
	
	windows = {}
	
	WINDOW_RENDER_TIME = 50
	
	newWindow = (cookie, locals) ->
		deferred = Q.defer()
		
		http.renderApp(locals).done (index) ->
			
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
			window = document.createWindow()
			
			# Capture "client" console logs.
			window.console = logger
			
			# Hack in WebSocket.
			window.WebSocket = require 'socket.io/node_modules/socket.io-client/node_modules/ws/lib/WebSocket'
			
			window.onload = ->
				
				# Inject Angular services so we can get up in its guts.
				shrub = window.shrub = {}
				injected = [
					'$location', '$rootScope', '$route', '$sniffer'
					'forms', 'socket'
				]
				invocation = injected.concat [
					-> shrub[inject] = arguments[i] for inject, i in injected
				]
				injector = window.angular.element(window.document).injector()
				injector.invoke invocation
				
				# Don't even try HTML 5 history on the server side.
				shrub.$sniffer.history = false
				
				# Windows expire after 5 minutes.
				_keepalive = _.debounce(
					-> window.close()
					1000 * 60 * 5
				)
				window.touch = ->
					_keepalive()
					window
				
				# Let the socket finish initialization.						
				shrub.socket.on 'initialized', -> deferred.resolve window
			
		deferred.promise
		
	angularWindow = (id, cookie, locals) ->
		deferred = Q.defer()
		
		# Already exists?
		if (window = windows[id])?
			deferred.resolve window
			
		# Create one otherwise.
		else
			deferred.resolve newWindow(cookie, locals).then (window) ->
				
				proxyClose = window.close
				window.close = ->
					
					# Temporary workaround for Contextify:
					# 
					# https://github.com/brianmcd/contextify/issues/89
					window.shrub.socket.disconnect()
					
					proxyClose.call this
					
					windows[id] = null
				
				windows[id] = window
		
		# Touch the window to keep it alive.	
		deferred.promise.then (window) -> window.touch()
	
	navigate = (window, path, body) ->
		deferred = Q.defer()
		
		shrub = window.shrub

		# If the path has changed, navigate Angular to it.			
		if path isnt url.parse(window.location.href).path
			unlisten = shrub.$rootScope.$on '$routeChangeSuccess', ->
				unlisten()
				deferred.resolve WINDOW_RENDER_TIME
				
			shrub.$rootScope.$apply -> shrub.$location.path path
		
		# Otherwise, we're already there.
		else
			deferred.resolve 0
		
		# Process any forms.
		deferred.promise.then (delay) ->
			return delay unless body.formKey?
			return delay unless (form = shrub.forms.lookup body.formKey)?
			
			for named in form.$element.find '[name]'
				continue unless (value = body[named.name])?
				form.$scope[named.name] = value
				
			form.$scope.$apply -> form.submit()
			
			# Give a few extra ms for form logic.
			delay + WINDOW_RENDER_TIME
		
	(req, res, next) ->
		{path} = url.parse req.url
		
		# e2e entry point hax.
		path = '/' if path is '/app/index.html'
		
		id = req.session.id
		locals = res.locals
		body = req.body
		
		# Uncomment to bypass the server-side Angular.		
#		return http.renderApp(locals).done (index) -> res.end index

		extractCookie = ->
			
			deferred = Q.defer()
			
			# If the client is in sync, awesome!
			if req.signedCookies[http.sessionKey()] is req.sessionID
				
				deferred.resolve req.headers.cookie
				
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
				req.session.save -> deferred.resolve cookie
				
			deferred.promise

		extractCookie().then (cookie) ->
			
			# Get a DOM window.
			angularWindow(id, cookie, locals).done (window) ->
				
				shrub = window.shrub
				
				routes = shrub.$route.routes
				if routes[path]?
				
					# Does this path redirect? Do an HTTP redirect.
					if routes[path].redirectTo?
						return res.redirect routes[path].redirectTo
					
				else
					
					# Is there no path entry? Check for a default.
					if routes[null]?
						return res.redirect routes[null].redirectTo
				
				# Navigate the Angular system to the new path.
				navigate(window, path, body).done (delay) ->
					
					# I'm not sure how to synchronize this.
					setTimeout(
						
						# Emit the HTML as it appears.
						-> res.end window.document.innerHTML
						
						delay
					)
