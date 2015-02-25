# Core client functionality.

*Coordinate various core functionality.*

    config = require 'config'

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubAngularAppRun`.

      registrar.registerHook 'shrubAngularAppRun', -> [
        '$rootScope', '$location', '$window', 'shrub-socket'
        ($rootScope, $location, $window, socket) ->

Split the path into the corresponding classes, e.g.

`foo/bar/baz` -> `class="foo foo-bar foo-bar-baz"`

          $rootScope.$watch (-> $location.path()), ->

            parts = $location.path().substr(1).split '/'
            parts = parts.map (part) -> part.replace /[^_a-zA-Z0-9-]/g, '-'

            classes = for i in [1..parts.length]
              parts.slice(0, i).join '-'

            $rootScope.pathClass = classes.join ' '

Navigate the client to `href`.

          socket.on 'core.navigateTo', (href) -> $window.location.href = href

Reload the client.

          socket.on 'core.reload', -> $window.location.reload()

Set up application close behavior.

          $window.addEventListener 'beforeunload', (event) ->
            appCloseEvent = $rootScope.$emit 'shrub.core.appClose'
            if appCloseEvent.defaultPrevented
              {confirmationMessage} = appCloseEvent
              event ?= $window.event
              event.returnValue = confirmationMessage

      ]

#### Implements hook `route`.

A simple path definition to make sure we're running in e2e testing mode.

      if 'e2e' is config.get 'packageConfig:shrub-core:testMode'
        registrar.registerHook 'e2e', 'route', -> path: 'e2e/sanity-check'
