
# # Angular
# 
# A sandboxed version of Angular, for clients lacking JS.

nconf = require 'nconf'
Promise = require 'bluebird'
url = require 'url'

middleware = require 'middleware'
sandboxes = require 'sandboxes'

# } The middleware dispatched every time sandboxed angular is navigated.
navigationMiddleware = []

# ## Implements hook `endpoint`
# 
# Allow a JSful client to call us back and inform us that we don't need to
# hold their sandbox.
exports.$endpoint = ->
	
	route: 'hangup'
	receiver: (req, fn) ->
		
		if (sandbox = sandboxes.lookup req.session?.id)?
			sandbox.close().finally -> fn()
		else
			fn()

# ## Implements hook `httpMiddleware`
# 
# If configuration dictates, render the client-side Angular application in a
# sandbox.
exports.$httpMiddleware = (http) ->
	
	label: 'Render page with Angular'
	middleware: [
	
		(req, res, next) ->
			
			settings = nconf.get 'packageSettings:angular'
			
			# } Render app.html
			htmlPromise = http.renderAppHtml res.locals
			
			# } Skip render in a sandbox?
			return htmlPromise.then(
				(html) -> res.end html
				(error) -> next error
			) unless settings.render
				
			# } Thrown when a request is complete.
			class ResponseComplete extends Error
				constructor: (@message) ->
			
			# } After the template is rendered, lookup or create the sandbox.
			htmlPromise.bind({}).then((html) ->
				
				sandboxes.lookupOrCreate(
					html, cookie, id

				# } Augment it.				
				).then (sandbox) -> exports.augmentSandbox sandbox
				
			).then((@sandbox) ->
				
				# } Emit the HTML from before the last redirection.
				if (redirectionHtml = @sandbox.redirectionHtml())?
					@sandbox.setRedirectionHtml null
					res.end redirectionHtml
					throw new ResponseComplete()
					
				# } Check for any new redirection and handle it.
				if (redirectionPath = @sandbox.redirectionPath())?
					@sandbox.setRedirectionPath null
					res.redirect redirectionPath
					throw new ResponseComplete()
					
				# } Prevent a possible race condition that would hang up the
				# } sandbox in between now and render.
				# 
				# } `TODO`: This should be a queue, not a busy promise.
				@deferred = Promise.defer()
				@sandbox.setBusy @deferred.promise
				
				{path} = url.parse req.url
				@sandbox.navigate path, req.body
				
			).then(->
				
				emission = @sandbox.emitHtml()
				
				# } Let any sandbox expirations take place now that we've
				# } emitted.
				@deferred.resolve()
				@sandbox.setBusy null
			
				# } If a redirect happened in the sandbox, actually redirect
				# } the browser and save the emission for the next request.
				if (redirectionPath = @sandbox.redirectionPath())?
					@sandbox.setRedirectionPath null
					@sandbox.setRedirectionHtml emission
					res.redirect redirectionPath
				
				# } Otherwise, just emit.	
				else
					
					res.end emission
				
			# } The request was completed early.
			).catch(ResponseComplete, ->
			
			).catch next
			
]

# ## Implements hook `initialize`
exports.$initialize = (config) ->

	# Always disable sandbox rendering in end-to-end testing mode.
	config.set 'packageSettings:angular:render', false if config.get 'E2E'

	# } Load the navigation middleware.
	navigationMiddleware = middleware.fromHook(
		'angularNavigationMiddleware'
		nconf.get 'packageSettings:angular:navigation:middleware'
	)

# ## Implements hook `packageSettings`
exports.$packageSettings = ->

	navigation:
	
		middleware: [
			'form'
		]

	# } Should we render in the sandbox?
	render: not process.env['E2E']?

# ## augmentSandbox
# 
# *Augment a sandbox with Angular-specific functionality.*
exports.augmentSandbox = (sandbox) ->
	
	# ### sandbox.(setR|r)edirectionHtml
	# 
	# *HTML to be delivered upon the next request using this sandbox.*
	# 
	# * (string) `html` - The HTML to be deliviered.
	redirectionHtml = null
	sandbox.redirectionHtml = -> redirectionHtml
	sandbox.setRedirectionHtml = (html) -> redirectionHtml = html
	
	# ### sandbox.(setR|r)edirectionPath
	# 
	# *The path that the client will be redirected to at the end of this
	# request.*
	# 
	# * (string) `path` - The URL path to redirect to.
	redirectionPath = null
	sandbox.redirectionPath = -> redirectionPath
	sandbox.setRedirectionPath = (path) -> redirectionPath = path
	
	# ### sandbox.catchAngularRedirection
	# 
	# *Check whether Angular was redirected, and set the client redirection
	# path if it was.*
	# 
	# * (string) `path` - URL path.
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
				
	# ### sandbox.checkPathChanges
	# 
	# *Check whether the navigation path is different than the current Angular
	# location path. If it is, redirect Angular.*
	# 
	# * (string) `path` - URL path.
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
			
			# } Nowhere to go?
			return resolve() if path is url.parse(@url()).path
			
			# } Navigate Angular to the request path.			
			unlisten = $rootScope.$on 'shrubFinishedRendering', =>
				unlisten()
				resolve()
				
			$rootScope.$apply -> $location.path path
		
	# ### sandbox.navigate
	# 
	# *Navigate angular to a path, and dispatch navigation middleware.*
	# 
	# * (string) `path` - URL path.
	# 
	# * (string) `body` - Request body.
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

	# ### sandbox.pathRedirectsTo
	# 
	# *Check where a path would be redirected by Angular's router.*
	# 
	# * (string) `path` - URL path.
	sandbox.pathRedirectsTo = (path) ->
		
		routes = null
		
		@inject [
			'$route'
			($route) -> routes = $route.routes
		]
		
		# } Perfect match.
		if routes[path]?
		
			# } Does this path redirect? Do an HTTP redirect.
			return routes[path].redirectTo if routes[path].redirectTo?
				
		else
			
			match = false
			
			# } Check for any regexs.
			for key, route of routes
				if route.regexp?.test path
					
					# } `TODO`: need to extract params to build redirectTo,
					# } small enough mismatch to ignore for now.
					return
			
			# } Angular's $routeProvider.otherwise() target.
			return routes[null].redirectTo if routes[null]?
	
	# ### sandbox.inject
	# 
	# *Inject an [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation) with dependencies.*
	# 
	# `TODO`: Return a promise, resolved with the dependency array.
	# 
	# * (mixed) `injectable` - An annontated function to inject with
	#   dependencies. 
	sandbox.inject = (injectable) ->
		
		injector = @_window.angular.element(@_window.document).injector()
		injector.invoke injectable
		
	# Make sure the socket is dead because Contextify will crash if an object
	# is accessed after it is disposed (and a socket will continue to
	# communicate and access `window` unless we close it).
	sandbox.registerCleanupFunction ->
		
		new Promise (resolve) ->
		
			sandbox.inject [
				'socket'
				(socket) ->
				
					socket.on 'disconnect', -> resolve()
					socket.disconnect()
				
			]
	
	# Do some initial configuration if the sandbox is new.
	return sandbox unless sandbox.isNew()
	new Promise (resolve, reject) ->
		
		sandbox.on 'ready', (error) ->
			
			# } Don't ignore errors, just pass them up.
			if error?
				sandbox.close()
				return reject error
			
			sandbox.inject [
				'$sniffer', 'socket'
				($sniffer, socket) ->
					
					# } Don't even try HTML 5 history on the server side.
					$sniffer.history = false
					
					# } Let the socket finish initialization.						
					socket.on 'initialized', -> resolve sandbox
			
			]
