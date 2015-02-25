# Angular sandbox

*A sandboxed version of Angular, for clients lacking JS.*

###### TODO: Sandbox pool, might be better handled by [sandboxes](source/server/sandboxes).

    _ = require 'lodash'
    Promise = require 'bluebird'
    url = require 'url'

    config = require 'config'
    debug = require('debug') 'shrub:angular'
    middleware = require 'middleware'
    {Sandbox} = require 'sandboxes'

The middleware dispatched every time sandboxed angular is navigated.

    navigationMiddleware = []

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `rpcRoutes`.

Allow a JSful client to call us back and inform us that we don't need to
hold their sandbox.

      registrar.registerHook 'rpcRoutes', ->

        routes = []

        routes.push

          path: 'shrub-angular-sandbox/hangup'
          receiver: (req, fn) ->

###### TODO: Cookie-less clients won't have a valid session ID to call with. This should be some other token, perhaps CSRF.

            id = req.session?.id
            if (sandbox = sandboxManager.lookup id)?
              sandbox.close().finally -> fn()
            else
              fn()

        return routes

#### Implements hook `shrubHttpMiddleware`.

If configuration dictates, render the client-side Angular application in a
sandbox.

      registrar.registerHook 'shrubHttpMiddleware', (http) ->

        label: 'Render page with Angular'
        middleware: [

          (req, res, next) ->

Skip render in a sandbox?

            settings = config.get 'packageSettings:shrub-angular'
            return next() unless settings.render

Thrown when a request is complete.

            class ResponseComplete extends Error
              constructor: (@message) ->

After the template is rendered, lookup or create the sandbox.

            Promise.resolve(req.delivery).bind({}).then((html) ->

              sandboxManager.lookupOrCreate(
                html
              ,
                cookie: req.headers.cookie

###### TODO: Multiline.

                url: "http://localhost:#{config.get 'packageSettings:shrub-http:port'}/shrub-angular-entry-point"
              ,
                req.session.id
              )

            ).then((@sandbox) ->

Emit the HTML from before the last redirection.

              if (redirectionHtml = @sandbox.redirectionHtml())?
                @sandbox.setRedirectionHtml null
                res.end redirectionHtml
                throw new ResponseComplete()

Check for any new redirection and handle it.

              if (redirectionPath = @sandbox.redirectionPath())?
                @sandbox.setRedirectionPath null
                res.redirect redirectionPath
                throw new ResponseComplete()

              @sandbox.navigate req

            ).then(->

              emission = @sandbox.emitHtml()

If a redirect happened in the sandbox, actually redirect
the browser and save the emission for the next request.

              if (redirectionPath = @sandbox.redirectionPath())?
                @sandbox.setRedirectionPath null
                @sandbox.setRedirectionHtml emission
                res.redirect redirectionPath

Otherwise, just emit.

              else

                req.delivery = emission
                next()

The request was completed early.

            ).catch(ResponseComplete, ->

            ).catch next

      ]

#### Implements hook `shrubCoreBootstrapMiddleware`.

      registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

        label: 'Bootstrap Angular'
        middleware: [

          (next) ->

Always disable sandbox rendering in end-to-end testing mode.

            if config.get 'E2E'
              config.set 'packageSettings:shrub-angular:render', false

#### Invoke hook `shrubAngularSandboxNavigationMiddleware`.

Load the navigation middleware.

            navigationMiddleware = middleware.fromConfig(
              'shrub-angular-sandbox:navigationMiddleware'
            )

            next()

        ]

#### Implements hook `shrubConfigServer`.

      registrar.registerHook 'shrubConfigServer', ->

Default navigation middleware.

        navigationMiddleware: [
          'shrub-form'
        ]

Should we render in the sandbox?

        render: true

Time-to-live for rendering sandboxes.

        ttl: 1000 * 60 * 5

This class handles instantiation of new sandboxes, as well as providing a
mechanism for registering and looking up persistent sandboxes using an id.

    sandboxManager = new class SandboxManager

## *constructor*

*Initialize the persistent store.*

      constructor: ->

        @_sandboxes = {}

## SandboxManager#create

* (string) `html` - The HTML to use as the sandbox document.
* (string) `cookie` - The cookie to use for the document.
* (optional string) `id` - An ID for looking up this sandbox later.

*Create a sandbox.*

      create: (html, options, id = null) ->

        debug "Creating sandbox ID: #{id}"

        sandbox = new Sandbox()
        sandbox.id = id

## Sandbox#close (monkeypatch)

*Remove from the manager when closing.*

        close = sandbox.close
        sandbox.close = =>
          debug "Closing sandbox ID: #{id}"

          @_sandboxes[id] = null
          close.apply sandbox

Create the document.

        (@_sandboxes[id] = sandbox).createDocument html, options

## SandboxManager#lookup

* (string) `id` - An ID for looking up this sandbox later.

*Look up a sandbox by ID.*

      lookup: (id) -> @_sandboxes[id]?.touch()

## SandboxManager#lookupOrCreate

* (string) `html` - The HTML to use as the sandbox document if creating.
* (string) `cookie` - The cookie to use for the document if creating.
* (optional string) `id` - An ID either for looking up later (if creating), or
  as a search now.

*Look up a sandbox by ID, or create one if none is registered for this
ID.*

      lookupOrCreate: (html, options, id = null) ->

        if (sandbox = @lookup id)?

          Promise.resolve sandbox

        else

          @create(html, options, id).then (sandbox) -> augmentSandbox sandbox

Augment a sandbox with Angular-specific functionality.

    augmentSandbox = (sandbox) ->

## Sandbox#touch

*Reset the time-to-live for a sandbox.*

      ttl = config.get 'packageSettings:shrub-angular:ttl'
      toucher = _.debounce (-> sandbox.close()), ttl
      do sandbox.touch = ->
        debug "Touched sandbox ID: #{id}"

        toucher()
        sandbox

## Sandbox#(setR|r)edirectionHtml

* (string) `html` - The HTML to be deliviered.

*HTML to be delivered upon the next request using this sandbox.*

      redirectionHtml = null
      sandbox.redirectionHtml = -> redirectionHtml
      sandbox.setRedirectionHtml = (html) -> redirectionHtml = html

## Sandbox#(setR|r)edirectionPath

* (string) `path` - The URL path to redirect to.

*The path that the client will be redirected to at the end of this
request.*

      redirectionPath = null
      sandbox.redirectionPath = -> redirectionPath
      sandbox.setRedirectionPath = (path) -> redirectionPath = path

## Sandbox#catchAngularRedirection

* (string) `path` - URL path.

*Check whether Angular was redirected, and set the client redirection
path if it was.*

      sandbox.catchAngularRedirection = (path) ->
        self = this

        @inject [
          '$location'
          ($location) ->

            return if path is $location.url()

            if redirect = self.pathRedirectsTo $location.url()
              self.setRedirectionPath redirect
            else
              self.setRedirectionPath $location.url()

        ]

## Sandbox#checkPathChanges

* (string) `path` - URL path.

*Check whether the navigation path is different than the current Angular
location path. If it is, redirect Angular.*

      sandbox.checkPathChanges = (path) ->
        self = this

        new Promise (resolve) ->

          self.inject [
            '$location', '$rootScope'
            ($location, $rootScope) ->

              # } Nowhere to go?
              return resolve() if path is url.parse(self.url()).path

              # } Navigate Angular to the request path.
              unlisten = $rootScope.$on 'shrub.core.routeRendered', ->
                unlisten()
                resolve()

              $rootScope.$apply -> $location.path path

          ]

## Sandbox#navigate

* (http.IncomingMessage) `req` - The HTTP request object.

*Navigate angular to a path, and dispatch navigation middleware.*

      sandbox.navigate = (req) ->
        self = this

        {path} = url.parse req.url

        @checkPathChanges(path).then ->

          new Promise (resolve, reject) ->

            navigationReq = Object.create req
            navigationReq.sandbox = sandbox

###### TODO: Remove unused `res` parameter.

            navigationMiddleware.dispatch navigationReq, (error) =>
              return reject error if error?

              self.catchAngularRedirection path
              resolve()

## Sandbox#pathRedirectsTo

* (string) `path` - URL path.

*Check where a path would be redirected by Angular's router.*

      sandbox.pathRedirectsTo = (path) ->

        routes = null

        @inject [
          '$route'
          ($route) -> routes = $route.routes
        ]

Perfect match.

        if routes[path]?

Does this path redirect? Do an HTTP redirect.

          return routes[path].redirectTo if routes[path].redirectTo?

        else

          match = false

Check for any regexs.

          for key, route of routes
            if route.regexp?.test path

###### TODO: Need to extract params to build redirectTo, it's a small enough mismatch to ignore for now.

              return

Angular's $routeProvider.otherwise() target.

          return routes[null].redirectTo if routes[null]?

## Sandbox#inject

* (mixed) `injectable` - An annotated function to inject with
  dependencies.

*Inject an
[annotated function](http://docs.angularjs.org/guide/di#dependency-annotation)
with dependencies.*

      sandbox.inject = (injectable) ->

        injector = @_window.angular.element(@_window.document).injector()
        injector.invoke injectable

Make sure the socket is dead.

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

Don't even try HTML 5 history on the server side.

            $sniffer.history = false

Let the socket finish initialization.

            socket.on 'initialized', -> resolve sandbox

        ]
