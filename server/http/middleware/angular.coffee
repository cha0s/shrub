
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
			
			# Set up a DOM starting with our entry point.
			document = jsdom(
				index
				null
				url: "http://localhost:#{http.port()}/shrub-entry-point"
			)
			
			# Hax for XMLHttpRequest
			document.cookie = cookie
			document._cookieDomain = 'localhost'
			
			window = document.createWindow()
			
			# Capture console logs.
			window.console = logger
			
			# Hack in WebSocket.
			window.WebSocket = require 'socket.io/node_modules/socket.io-client/node_modules/ws/lib/WebSocket'
			
			# Inject Angular services so we can get up in its guts.
			shrub = window.shrub = {}
			injected = [
				'$location', '$rootScope', '$route', '$sniffer', 'forms', 'socket'
			]
			invocation = injected.concat [
				-> shrub[inject] = arguments[i] for inject, i in injected
			]
			window.shrubInjector = ($injector) -> $injector.invoke invocation
				
			window.onload = ->
				
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
		
		# Get a DOM window.
		angularWindow(id, req.headers.cookie, locals).done (window) ->
			
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
					->
						
						# Emit the HTML as it appears.
						res.end window.document.innerHTML
					delay
				)
