# Core client functionality.

*Coordinate various core functionality.*

```coffeescript
config = require 'config'

exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubAngularAppRun`](../../../hooks#shrubangularapprun)

```coffeescript
  registrar.registerHook 'shrubAngularAppRun', -> [
    '$rootScope', '$location', '$window', 'shrub-socket'
    ($rootScope, $location, $window, socket) ->
```

Split the path into the corresponding classes, e.g. `foo/bar/baz` ->
`class="foo foo-bar foo-bar-baz"`

```coffeescript
      $rootScope.$watch (-> $location.path()), ->

        parts = $location.path().substr(1).split '/'
        parts = parts.map (part) -> part.replace /[^_a-zA-Z0-9-]/g, '-'

        classes = for i in [1..parts.length]
          parts.slice(0, i).join '-'

        $rootScope.pathClass = classes.join ' '
```

Navigate the client to `href`.

```coffeescript
      socket.on 'core.navigateTo', (href) -> $window.location.href = href
```

Reload the client.

```coffeescript
      socket.on 'core.reload', -> $window.location.reload()
```

Set up application close behavior.

```coffeescript
      $window.addEventListener 'beforeunload', (event) ->
        appCloseEvent = $rootScope.$emit 'shrub.core.appClose'
        if appCloseEvent.defaultPrevented
          {confirmationMessage} = appCloseEvent
          event ?= $window.event
          event.returnValue = confirmationMessage

  ]
```

#### Implements hook [`shrubAngularRoutes`](../../../hooks#shrubangularroutes)

A simple path definition to make sure we're running in e2e testing mode.

```coffeescript
  registrar.registerHook 'shrubAngularRoutes', ->

    routes = []

    if 'e2e' is config.get 'packageConfig:shrub-core:testMode'
      routes.push
        path: 'e2e/sanity-check'

    return routes
```
