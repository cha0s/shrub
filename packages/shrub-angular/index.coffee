
# # Angular
#
# A sandboxed version of Angular, for clients lacking JS.

_ = require 'lodash'
Promise = require 'bluebird'
url = require 'url'

config = require 'config'
debug = require('debug') 'shrub:angular'
middleware = require 'middleware'
{Sandbox} = require 'sandboxes'

# } The middleware dispatched every time sandboxed angular is navigated.
navigationMiddleware = []

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `endpoint`
	#
	# Allow a JSful client to call us back and inform us that we don't need to
	# hold their sandbox.
	registrar.registerHook 'endpoint', ->

		route: 'shrub.hangup'
		receiver: (req, fn) ->

			id = req.session?.id
			if (sandbox = sandboxManager.lookup id)?
				sandbox.close().finally -> fn()
			else
				fn()

	# ## Implements hook `httpMiddleware`
	#
	# If configuration dictates, render the client-side Angular application in a
	# sandbox.
	registrar.registerHook 'httpMiddleware', (http) ->

		label: 'Render page with Angular'
		middleware: [

			(req, res, next) ->

				settings = config.get 'packageSettings:shrub-angular'

				# } Skip render in a sandbox?
				return next() unless settings.render

				# } Thrown when a request is complete.
				class ResponseComplete extends Error
					constructor: (@message) ->

				# } After the template is rendered, lookup or create the sandbox.
				Promise.resolve(req.delivery).bind({}).then((html) ->

					sandboxManager.lookupOrCreate(
						html
					,
						cookie: req.headers.cookie
						url: "http://localhost:#{
							config.get 'packageSettings:shrub-http:port'
						}/shrub-entry-point"
					,
						req.session.id
					)

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

					{path} = url.parse req.url
					@sandbox.navigate path, req.body

				).then(->

					emission = @sandbox.emitHtml()

					# } If a redirect happened in the sandbox, actually redirect
					# } the browser and save the emission for the next request.
					if (redirectionPath = @sandbox.redirectionPath())?
						@sandbox.setRedirectionPath null
						@sandbox.setRedirectionHtml emission
						res.redirect redirectionPath

					# } Otherwise, just emit.
					else

						req.delivery = emission
						next()

				# } The request was completed early.
				).catch(ResponseComplete, ->

				).catch next

	]

	# ## Implements hook `bootstrapMiddleware`
	registrar.registerHook 'bootstrapMiddleware', ->

		label: 'Bootstrap Angular'
		middleware: [

			(next) ->

				# Always disable sandbox rendering in end-to-end testing mode.
				if config.get 'E2E'
					config.set 'packageSettings:shrub-angular:render', false

				# } Load the navigation middleware.
				navigationMiddleware = middleware.fromShortName(
					'angular navigation', 'shrub-angular'
				)

				next()

		]

	# ## Implements hook `packageSettings`
	registrar.registerHook 'packageSettings', ->

		navigationMiddleware: [
			'shrub-form'
		]

		# } Should we render in the sandbox?
		render: true

		# } Time-to-live for rendering sandboxes.
		ttl: 1000 * 60 * 5

# ## SandboxManager
# This class handles instantiation of new sandboxes, as well as providing a
# mechanism for registering and looking up persistent sandboxes using an id.
sandboxManager = new class SandboxManager

	# ### *constructor*
	#
	# *Initialize the persistent store.*
	constructor: ->

		@_sandboxes = {}

	# ### .create
	#
	# *Create a sandbox.*
	#
	# * (string) `html` - The HTML to use as the sandbox document.
	# * (string) `cookie` - The cookie to use for the document.
	# * (string) `id`? - An ID for looking up this sandbox later.
	create: (html, options, id = null) ->

		debug "Creating sandbox ID: #{id}"

		sandbox = new Sandbox()
		sandbox.id = id

		# ### sandbox.touch
		#
		# *Reset the time-to-live for a sandbox.*
		ttl = config.get 'packageSettings:shrub-angular:ttl'
		toucher = _.debounce (=> sandbox.close()), ttl
		do sandbox.touch = ->
			debug "Touched sandbox ID: #{id}"

			toucher()
			sandbox

		# Remove from the manager when closing.
		close = sandbox.close
		sandbox.close = =>
			debug "Closing sandbox ID: #{id}"

			@_sandboxes[id] = null
			close.apply sandbox

		# Create the document.
		(@_sandboxes[id] = sandbox).createDocument html, options

	# ### .lookup
	#
	# *Look up a sandbox by ID.*
	#
	# * (string) `id` - An ID for looking up this sandbox later.
	lookup: (id) -> @_sandboxes[id]?.touch()

	# ### .lookupOrCreate
	#
	# *Look up a sandbox by ID, or create one if none is registered for this
	# ID.*
	#
	# * (string) `html` - The HTML to use as the sandbox document if creating.
	# * (string) `cookie` - The cookie to use for the document if creating.
	# * (string) `id`? - An ID either for looking up later (if creating), or
	#   as a search now.
	lookupOrCreate: (html, options, id = null) ->

		promise = if (sandbox = @lookup id)?

			Promise.resolve sandbox

		else

			@create(html, options, id).then (sandbox) ->
				exports.augmentSandbox sandbox

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
			unlisten = $rootScope.$on 'shrub.core.routeRendered', =>
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
	# * (mixed) `injectable` - An annotated function to inject with
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
				'shrub-socket'
				(socket) ->

					socket.on 'disconnect', -> resolve()
					socket.disconnect()

			]

	new Promise (resolve) ->

		sandbox.inject [
			'$sniffer', 'shrub-socket'
			($sniffer, socket) ->

				# } Don't even try HTML 5 history on the server side.
				$sniffer.history = false

				# } Let the socket finish initialization.
				socket.on 'initialized', -> resolve sandbox

		]
