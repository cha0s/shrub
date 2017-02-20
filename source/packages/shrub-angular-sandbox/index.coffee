# Angular sandbox

*A sandboxed version of Angular, for clients lacking JS.*

###### TODO: Sandbox pool, might be better handled by [sandboxes](source/server/sandboxes).

```coffeescript
_ = require 'lodash'
Promise = require 'bluebird'
url = require 'url'

config = require 'config'
debug = require('debug') 'shrub:angular'
middleware = require 'middleware'
{Sandbox} = require 'sandboxes'
```

The middleware dispatched every time sandboxed angular is navigated.

```coffeescript
navigationMiddleware = []

exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubRpcRoutes`](../../hooks#shrubrpcroutes)

Allow a JSful client to call us back and inform us that we don't need to
hold their sandbox.

```coffeescript
  registrar.registerHook 'shrubRpcRoutes', ->

    routes = []

    routes.push

      path: 'shrub-angular-sandbox/hangup'
      middleware: [

        'shrub-http-express/session'

        (req, res, next) ->
```

###### TODO: Cookie-less clients won't have a valid session ID to call with. This should be some other token, perhaps CSRF.

```coffeescript
          id = req.session?.id
          if (sandbox = sandboxManager.lookup id)?
            sandbox.close().finally -> res.end()
          else
            res.end()

      ]

    return routes
```

#### Implements hook [`shrubHttpMiddleware`](../../hooks#shrubhttpmiddleware)

If configuration dictates, render the client-side Angular application in a
sandbox.

```coffeescript
  registrar.registerHook 'shrubHttpMiddleware', (http) ->

    label: 'Render page with Angular'
    middleware: [

      (req, res, next) ->
```

Skip render in a sandbox?

```coffeescript
        settings = config.get 'packageConfig:shrub-angular'
        return next() unless settings.render
```

Thrown when a request is complete.

```coffeescript
        class ResponseComplete extends Error
          constructor: (@message) ->
```

After the template is rendered, lookup or create the sandbox.

```coffeescript
        Promise.resolve(req.delivery).bind({}).then((html) ->

          sandboxManager.lookupOrCreate(
            html
          ,
            cookie: req.headers.cookie

            url: "http://#{
              config.get 'packageConfig:shrub-core:siteHostname'
            }/shrub-angular-entry-point"
          ,
            req.session.id
          )

        ).then((@sandbox) ->
```

Emit the HTML from before the last redirection.

```coffeescript
          if (redirectionHtml = @sandbox.redirectionHtml())?
            @sandbox.setRedirectionHtml null
            res.end redirectionHtml
            throw new ResponseComplete()
```

Check for any new redirection and handle it.

```coffeescript
          if (redirectionPath = @sandbox.redirectionPath())?
            @sandbox.setRedirectionPath null
            res.redirect redirectionPath
            throw new ResponseComplete()

          @sandbox.navigate req

        ).then(->

          emission = @sandbox.emitHtml()
```

If a redirect happened in the sandbox, actually redirect the
browser and save the emission for the next request.

```coffeescript
          if (redirectionPath = @sandbox.redirectionPath())?
            @sandbox.setRedirectionPath null
            @sandbox.setRedirectionHtml emission
            res.redirect redirectionPath
```

Otherwise, just emit.

```coffeescript
          else

            req.delivery = emission
            next()
```

The request was completed early.

```coffeescript
        ).catch(ResponseComplete, ->

        ).catch next

  ]
```

#### Implements hook [`shrubCoreBootstrapMiddleware`](../../hooks#shrubcorebootstrapmiddleware)

```coffeescript
  registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

    label: 'Bootstrap Angular'
    middleware: [

      (next) ->
```

Always disable sandbox rendering in end-to-end testing mode.

```coffeescript
        if config.get 'E2E'
          config.set 'packageConfig:shrub-angular:render', false
```

#### Invoke hook [`shrubAngularSandboxNavigationMiddleware`](../../hooks#shrubangularsandboxnavigationmiddleware)

Load the navigation middleware.

```coffeescript
        navigationMiddleware = middleware.fromConfig(
          'shrub-angular-sandbox:navigationMiddleware'
        )

        next()

    ]
```

#### Implements hook [`shrubConfigServer`](../../hooks#shrubconfigserver)

```coffeescript
  registrar.registerHook 'shrubConfigServer', ->
```

Default navigation middleware.

```coffeescript
    navigationMiddleware: [
      'shrub-form'
    ]
```

Should we render in the sandbox?

```coffeescript
    render: true
```

Time-to-live for rendering sandboxes.

```coffeescript
    ttl: 1000 * 60 * 5
```

This class handles instantiation of new sandboxes, as well as providing a
mechanism for registering and looking up persistent sandboxes using an id.

```coffeescript
sandboxManager = new class SandboxManager
```

## *constructor*

*Initialize the persistent store.*

```coffeescript
  constructor: ->

    @_sandboxes = {}
```

## SandboxManager#create

* (string) `html` - The HTML to use as the sandbox document.

* (string) `cookie` - The cookie to use for the document.

* (optional string) `id` - An ID for looking up this sandbox later.

*Create a sandbox.*

```coffeescript
  create: (html, options, id = null) ->

    debug "Creating sandbox ID: #{id}"

    sandbox = new Sandbox()
    sandbox.id = id
```

## Sandbox#close (monkeypatch)

*Remove from the manager when closing.*

```coffeescript
    close = sandbox.close
    sandbox.close = =>
      debug "Closing sandbox ID: #{id}"

      @_sandboxes[id] = null
      close.apply sandbox
```

Create the document.

```coffeescript
    (@_sandboxes[id] = sandbox).createDocument html, options
```

## SandboxManager#lookup

* (string) `id` - An ID for looking up this sandbox later.

*Look up a sandbox by ID.*

```coffeescript
  lookup: (id) -> @_sandboxes[id]?.touch()
```

## SandboxManager#lookupOrCreate

* (string) `html` - The HTML to use as the sandbox document if creating.

* (string) `cookie` - The cookie to use for the document if creating.

* (optional string) `id` - An ID either for looking up later (if
creating), or as a search now.

*Look up a sandbox by ID, or create one if none is registered for this
ID.*

```coffeescript
  lookupOrCreate: (html, options, id = null) ->

    if (sandbox = @lookup id)?

      Promise.resolve sandbox

    else

      @create(html, options, id).then (sandbox) -> augmentSandbox sandbox
```

Augment a sandbox with Angular-specific functionality.

```coffeescript
augmentSandbox = (sandbox) ->
```

## Sandbox#touch

*Reset the time-to-live for a sandbox.*

```coffeescript
  ttl = config.get 'packageConfig:shrub-angular:ttl'
  toucher = _.debounce (-> sandbox.close()), ttl
  do sandbox.touch = ->
    debug "Touched sandbox ID: #{id}"

    toucher()
    sandbox
```

## Sandbox#(setR|r)edirectionHtml

* (string) `html` - The HTML to be deliviered.

*HTML to be delivered upon the next request using this sandbox.*

```coffeescript
  redirectionHtml = null
  sandbox.redirectionHtml = -> redirectionHtml
  sandbox.setRedirectionHtml = (html) -> redirectionHtml = html
```

## Sandbox#(setR|r)edirectionPath

* (string) `path` - The URL path to redirect to.

*The path that the client will be redirected to at the end of this
request.*

```coffeescript
  redirectionPath = null
  sandbox.redirectionPath = -> redirectionPath
  sandbox.setRedirectionPath = (path) -> redirectionPath = path
```

## Sandbox#catchAngularRedirection

* (string) `path` - URL path.

*Check whether Angular was redirected, and set the client redirection path
if it was.*

```coffeescript
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
```

## Sandbox#checkPathChanges

* (string) `path` - URL path.

*Check whether the navigation path is different than the current Angular
location path. If it is, redirect Angular.*

```coffeescript
  sandbox.checkPathChanges = (path) ->
    self = this

    new Promise (resolve) ->

      self.inject [
        '$location', '$rootScope'
        ($location, $rootScope) ->
```

} Nowhere to go?

```coffeescript
          return resolve() if path is url.parse(self.url()).path
```

} Navigate Angular to the request path.

```coffeescript
          unlisten = $rootScope.$on 'shrub.core.routeRendered', ->
            unlisten()
            resolve()

          $rootScope.$apply -> $location.path path

      ]
```

## Sandbox#navigate

* (http.IncomingMessage) `req` - The HTTP request object.

*Navigate angular to a path, and dispatch navigation middleware.*

```coffeescript
  sandbox.navigate = (req) ->
    self = this

    {path} = url.parse req.url

    @checkPathChanges(path).then ->

      new Promise (resolve, reject) ->

        navigationReq = Object.create req
        navigationReq.sandbox = sandbox

        navigationMiddleware.dispatch navigationReq, (error) =>
          return reject error if error?

          self.catchAngularRedirection path
          resolve()
```

## Sandbox#pathRedirectsTo

* (string) `path` - URL path.

*Check where a path would be redirected by Angular's router.*

```coffeescript
  sandbox.pathRedirectsTo = (path) ->

    routes = null

    @inject [
      '$route'
      ($route) -> routes = $route.routes
    ]
```

Perfect match.

```coffeescript
    if routes[path]?
```

Does this path redirect? Do an HTTP redirect.

```coffeescript
      return routes[path].redirectTo if routes[path].redirectTo?

    else

      match = false
```

Check for any regexs.

```coffeescript
      for key, route of routes
        if route.regexp?.test path
```

###### TODO: Need to extract params to build redirectTo, it's a small enough mismatch to ignore for now.

```coffeescript
          return
```

Angular's $routeProvider.otherwise() target.

```coffeescript
      return routes[null].redirectTo if routes[null]?
```

## Sandbox#inject

* (mixed) `injectable` - An annotated function to inject with dependencies.

*Inject an [annotated
function](http://docs.angularjs.org/guide/di#dependency-annotation) with
dependencies.*

```coffeescript
  sandbox.inject = (injectable) ->

    injector = @_window.angular.element(@_window.document).injector()
    injector.invoke injectable
```

Make sure the socket is dead.

```coffeescript
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
```

Don't even try HTML 5 history on the server side.

```coffeescript
        $sniffer.history = false
```

Let the socket finish initialization.

```coffeescript
        socket.on 'initialized', -> resolve sandbox

    ]
```
