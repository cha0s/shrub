
nconf = require 'nconf'
Promise = require 'bluebird'
url = require 'url'

sandboxes = require 'sandboxes'

exports.$endpoint = ->
	
	route: 'hangup'
	receiver: (req, fn) ->
		
		return fn() unless (sandbox = sandboxes.lookup req.session?.id)?
		sandbox.close().finally -> fn()

exports.$httpMiddleware = (http) ->
	
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
				
				# Reload the session, server-side JS socket stuff could
				# have changed it!
				Promise.promisify(req.session.reload, req.session)()
				
			).then(->
				
				emission = @sandbox.emitHtml()
				
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
				
				# Let any sandbox expirations take place now that we've
				# emitted.
				@deferred.resolve()
				@sandbox.setBusy null
			
			).catch(ResponseComplete, ->
			
			).catch (error) ->
				
				next error
			
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
	
			# If the request path isn't the Angular path, navigate Angular to
			# the request path.			
			if path isnt url.parse(@url()).path
				
				unlisten = $rootScope.$on 'shrubFinishedRendering', =>
					unlisten()
					
					@catchAngularRedirection path
						
					resolve()
					
				$rootScope.$apply -> $location.path path
			
			# Otherwise, we're already there.
			else
				resolve()
		
	sandbox.navigate = (path, body) ->
	
		$location = null
		$rootScope = null
		shrubForm = null
		
		@inject [
			'$location', '$rootScope', 'form'
			(_$location_, _$rootScope_, form) ->
				$location = _$location_
				$rootScope = _$rootScope_
				shrubForm = form
		]
	
		originalUrl = $location.url()
		
		@checkPathChanges(
			path
			
		).then =>
		
			return unless body.formKey?
			return unless (formSpec = shrubForm.lookup body.formKey)?
			
			scope = formSpec.scope
			form = scope[body.formKey]
			
			for named in formSpec.element.find '[name]'
				continue unless (value = body[named.name])?
				scope[named.name] = value
				
			new Promise (resolve) =>
			
				# Submit handlers return promises.
				scope.$apply => form.submit.handler().finally =>
					
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
		
	new Promise (resolve) ->
		
		sandbox.on 'ready', ->
			
			sandbox.inject [
				'$sniffer', 'socket'
				($sniffer, socket) ->
					
					# Don't even try HTML 5 history on the server side.
					$sniffer.history = false
					
					# Let the socket finish initialization.						
					socket.on 'initialized', -> resolve sandbox
			
			]
