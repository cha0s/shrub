# Core client functionality.

*Coordinate various core functionality.*

    Promise = require 'bluebird'

    config = require 'config'

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `aHrefSanitizationWhitelist`.

      registrar.registerHook 'aHrefSanitizationWhitelist', -> [

Allow more protocols.

        '(?:https?|ftp|mailto|tel|file):'

Allow javascript:void(0).

        'javascript:void(?:%20)*\\((?:%20)*0(?:%20)*\\)'
      ]

#### Implements hook `appConfig`.

      registrar.registerHook 'appConfig', -> [
        '$compileProvider', '$injector', '$provide', '$routeProvider', '$locationProvider', 'shrub-pkgmanProvider'
        ($compileProvider, $injector, $provide, $routeProvider, $locationProvider, pkgmanProvider) ->

#### Invoke hook `aHrefSanitizationWhilelist`.

Allow packages to define whitelisted patterns for ngHref
attributes.

          regexes = []
          for regexes_ in pkgmanProvider.invokeFlat(
            'aHrefSanitizationWhitelist'
          )
            regexes.push regex for regex in regexes_

          $compileProvider.aHrefSanitizationWhitelist new RegExp(
            "^\s*(?:#{regexes.join '|'})"
          )

Completely override $q with Bluebird, because it's awesome.

###### TODO: Angular also implements a private service called $$q used for animation. We should override that one, too.

          $provide.decorator '$q', [
            '$rootScope', '$exceptionHandler'
            ($rootScope, $exceptionHandler) ->

              Promise.onPossiblyUnhandledRejection (error) ->

$timeout and $interval will throw this for cancellation. It's non-notable.

                return if 'canceled' is error.message

                $exceptionHandler error

Hook Bluebird's schedule up to Angular.

              Promise.setScheduler (fn) -> $rootScope.$evalAsync fn

## Promise.defer

See: https://docs.angularjs.org/api/ng/service/$q#the-deferred-api

              Promise.defer = ->
                resolve = null
                reject = null

                promise = new Promise ->
                  resolve = arguments[0]
                  reject = arguments[1]

                promise: promise
                resolve: resolve
                reject: reject

## Promise.when

See: https://docs.angularjs.org/api/ng/service/$q#when

              Promise.when = (value, handlers...) ->
                Promise.cast(value).then handlers...

Proxy Promise.all because Angular supports passing in an object where the
values are promises, and the result is an object keyed with the resolved
values from the promise.

              originalAll = Promise.all
              Promise.all = (promises) ->

Defer to Bluebird unless it's an object.

                return originalAll promises unless angular.isObject(
                  promises
                )

Track the keys so we can map the values.

                promiseKeys = []
                promiseArray = for key, promise of promises
                  promiseKeys.push key
                  promise

                originalAll(promiseArray).then (results) ->
                  objectResult = {}

                  for result, index in results
                    objectResult[promiseKeys[index]] = result

                  objectResult

              Promise

          ]

A route is defined like:

* (AnnotatedFunction) `controller`: An
  [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation)
  which will be injected.
* (string) `template`: A template.
* (string) `title`: The page title.

#### Invoke hook `route`.

Allow packages to define routes in the Angular application.

          routes = {}
          for path, route of pkgmanProvider.invoke 'route'
            routes[route.path ? path] = route

Invoke hook `routeAlter`.

Allow packages to alter defined routes.

          $injector.invoke(
            injectable, null
            routes: routes
          ) for injectable in pkgmanProvider.invokeFlat 'routeAlter'

          for path, route of routes
            do (path, route) ->

Wrap the controller so we can provide some automatic behavior.

              routeController = route.controller
              route.controller = [
                '$controller', '$injector', '$q', '$scope'
                ($controller, $injector, $q, $scope) ->

Invoke hook `routeControllerStart`.

Allow packages to act before a new route
controller is executed.

                  $injector.invoke(
                    injectable, null
                    $scope: $scope
                    route: route
                  ) for injectable in pkgmanProvider.invokeFlat(
                    'routeControllerStart'
                  )

                  unless routeController?
                    return $scope.$emit 'shrub.core.routeRendered'

Controllers may return a promise, so wait until any returned value fulfills.
If it's not a promise, this will be in the next tick.

                  $q.when($injector.invoke(
                    routeController, null
                    $scope: $scope
                    route: route
                  )).then(-> $scope.$emit 'shrub.core.routeRendered').done()

              ]

              route.template ?= ' '

Register the path into Angular.

              $routeProvider.when "/#{route.path ? path}", route

Create a unique entry point.

          $routeProvider.when '/shrub-entry-point', {}

Turn on HTML5 mode: "Real" URLs.

          $locationProvider.html5Mode true
      ]

#### Implements hook `appRun`.

      registrar.registerHook 'appRun', -> [
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

      if 'e2e' is config.get 'testMode'
        registrar.registerHook 'e2e', 'route', -> path: 'e2e/sanity-check'
