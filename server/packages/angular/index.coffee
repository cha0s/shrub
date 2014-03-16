
nconf = require 'nconf'
Promise = require 'bluebird'
url = require 'url'

middleware = require 'middleware'
sandboxes = require 'sandboxes'

navigationMiddleware = []

exports.$endpoint = ->
	
	route: 'hangup'
	receiver: (req, fn) ->
		
		return fn() unless (sandbox = sandboxes.lookup req.session?.id)?
		sandbox.close().finally -> fn()

exports.$httpMiddleware = (http) ->
	
	# Load the navigation middleware.
	navigationMiddleware = middleware.fromHook(
		'angularNavigationMiddleware'
		nconf.get 'angular:navigation:middleware'
	)
	
	label: 'Render page with Angular'
	middleware: [
	
		(req, res, next) ->
			
			# Render app.html
			htmlPromise = http.renderAppHtml res.locals
			
			# Skip render in a sandbox?
			return htmlPromise.then(
				(html) -> res.end html
				(error) -> next error
			) unless nconf.get 'sandboxes:render'
				
			# Sort of a hack to conditionally break out of promise flow.
			class ResponseComplete extends Error
				constructor: (@message) ->
			
			htmlPromise.bind({}).then((html) ->
				
				lookupOrCreateAugmentedSandbox(
					html, req.headers.cookie, req.session.id
				)
				
			).then((@sandbox) ->
				
				# Emit the HTML from before the last redirection.
				if (redirectionHtml = @sandbox.redirectionHtml())?
					@sandbox.setRedirectionHtml null
					res.end redirectionHtml
					throw new ResponseComplete()
					
				# Check for any new redirection and handle it.
				if (redirectionPath = @sandbox.redirectionPath())?
					@sandbox.setRedirectionPath null
					res.redirect redirectionPath
					throw new ResponseComplete()
					
				# Prevent a possible race condition that would hang up the
				# sandbox in between now and render.
				@deferred = Promise.defer()
				@sandbox.setBusy @deferred.promise
				
				{path} = url.parse req.url
				@sandbox.navigate path, req.body
				
			).then(->
				
				emission = @sandbox.emitHtml()
				
				# Let any sandbox expirations take place now that we've
				# emitted.
				@deferred.resolve()
				@sandbox.setBusy null
			
				# If a redirect happened in the sandbox, actually redirect the
				# browser and save the emission for the next request.
				if (redirectionPath = @sandbox.redirectionPath())?
					@sandbox.setRedirectionPath null
					@sandbox.setRedirectionHtml emission
					res.redirect redirectionPath
				
				# Otherwise, just emit.	
				else
					
					# Emit.
					res.end emission
				
			).catch(ResponseComplete, ->
			
			).catch (error) -> next error
			
]

lookupOrCreateAugmentedSandbox = (html, cookie, id) ->
	
	sandboxes.lookupOrCreate(
		html, cookie, id
	
	).then (sandbox) -> exports.augmentSandbox sandbox
	
exports.augmentSandbox = (sandbox) ->
	
	redirectionHtml = null
	sandbox.redirectionHtml = -> redirectionHtml
	sandbox.setRedirectionHtml = (html) -> redirectionHtml = html
	
	redirectionPath = null
	sandbox.redirectionPath = -> redirectionPath
	sandbox.setRedirectionPath = (path) -> redirectionPath = path
	
	sandbox.catchAngularRedirection = (path) ->
	
		$location = null
		
		@inject [
			'$location'
			(_$location_) -> $location = _$location_
		]

		if path isnt $location.url()
			if redirect = @pathRedirectsTo $location.url()
				@setRedirectionPath redirect
			else
				@setRedirectionPath $location.url()
				
	sandbox.checkPathChanges = (path) ->
	
		$location = null
		$rootScope = null
		
		@inject [
			'$location', '$rootScope'
			(_$location_, _$rootScope_) ->
				$location = _$location_
				$rootScope = _$rootScope_
		]
		
		new Promise (resolve) =>
			
			# Nowhere to go?
			return resolve() if path is url.parse(@url()).path
			
			# Navigate Angular to the request path.			
			unlisten = $rootScope.$on 'shrubFinishedRendering', =>
				unlisten()
				resolve()
				
			$rootScope.$apply -> $location.path path
		
	sandbox.navigate = (path, body) ->
	
		@checkPathChanges(
			path
			
		).then =>
			
			new Promise (resolve, reject) =>
			
				req =
					body: body
					path: path
					sandbox: sandbox
				
				navigationMiddleware.dispatch req, null, (error) =>
					return reject error if error?
					
					@catchAngularRedirection path
					resolve()

	sandbox.pathRedirectsTo = (path) ->
		
		routes = null
		
		@inject [
			'$route'
			($route) -> routes = $route.routes
		]
		
		# Perfect match.
		if routes[path]?
		
			# Does this path redirect? Do an HTTP redirect.
			return routes[path].redirectTo if routes[path].redirectTo?
				
		else
			
			match = false
			
			# Check for any regexs.
			for key, route of routes
				if route.regexp?.test path
					
					# TODO need to extract params to build
					# redirectTo, small enough mismatch to ignore
					# for now.
					return
			
			# Otherwise.
			return routes[null].redirectTo if routes[null]?
	
	sandbox.inject = (injected) ->
		
		# Inject Angular services so we can get up in its guts.
		injector = @_window.angular.element(@_window.document).injector()
		injector.invoke injected
		
	sandbox.registerCleanupFunction ->
		
		new Promise (resolve) ->
		
			# Make sure the socket is dead because Contextify will crash if an
			# object is accessed after it is disposed (and a socket will
			# continue to communicate and access 'window' unless we close it).
			sandbox.inject [
				'socket'
				(socket) ->
				
					socket.on 'disconnect', -> resolve()
					socket.disconnect()
				
			]
	
	return sandbox unless sandbox.isNew()
		
	new Promise (resolve, reject) ->
		
		sandbox.on 'ready', (error) ->
			if error?
				sandbox.close()
				return reject error
			
			sandbox.inject [
				'$sniffer', 'socket'
				($sniffer, socket) ->
					
					# Don't even try HTML 5 history on the server side.
					$sniffer.history = false
					
					# Let the socket finish initialization.						
					socket.on 'initialized', -> resolve sandbox
			
			]
