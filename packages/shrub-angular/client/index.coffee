# # Angular
#
# *Coordinate various core functionality.*
_ = require 'lodash'
Promise = require 'bluebird'

config = require 'config'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubAngularAHrefSanitizationWhitelist`.
  registrar.registerHook 'shrubAngularAHrefSanitizationWhitelist', -> [

    # Allow more protocols.
    '(?:https?|ftp|mailto|tel|file):'

    # Allow javascript:void(0).
    'javascript:void\\(0\\)'
  ]

  # #### Implements hook `shrubAngularAppConfig`.
  registrar.registerHook 'shrubAngularAppConfig', -> [
    '$compileProvider', '$injector', '$provide', '$routeProvider', '$locationProvider', 'shrub-pkgmanProvider'
    ($compileProvider, $injector, $provide, $routeProvider, $locationProvider, pkgmanProvider) ->

      # #### Invoke hook `shrubAngularAHrefSanitizationWhitelist`.
      regexes = []
      for regexes_ in pkgmanProvider.invokeFlat(
        'shrubAngularAHrefSanitizationWhitelist'
      )
        regexes.push regex for regex in regexes_

      $compileProvider.aHrefSanitizationWhitelist new RegExp(
        "^\s*(?:#{regexes.join '|'})"
      )

      # Attach debug info if we're in test mode.
      unless config.get 'packageConfig:shrub-core:testMode'
        $compileProvider.debugInfoEnabled false

      # Completely override the $q service with Bluebird, because it's
      # awesome.
      #
      # ###### TODO: Angular also implements a private service called $$q used for animation. We should override that one, too.
      $provide.decorator '$q', [
        '$rootScope', '$exceptionHandler'
        ($rootScope, $exceptionHandler) ->

          Promise.onPossiblyUnhandledRejection (error) ->

            # $timeout and $interval will throw this for cancellation. It's
            # non-notable.
            return if 'canceled' is error.message

            $exceptionHandler error

          # Hook Bluebird's schedule up to Angular.
          Promise.setScheduler (fn) -> $rootScope.$evalAsync fn

          # ## Promise.defer
          #
          # See: https://docs.angularjs.org/api/ng/service/$q#the-deferred-api
          Promise.defer = ->
            resolve = null
            reject = null

            # Create a promise.
            promise = new Promise ->
              resolve = arguments[0]

              # Angular is a scrub, and will reject promises with strings
              # instead of fully-fledged Error instances. Hold its hand.
              reject_ = arguments[1]
              reject = (error) ->
                error = new Error error if _.isString error
                reject_ error

              return

            # Angular depends on notify, which is a crap API. We'll hack
            # support for it in.
            __notifications = []
            proxyThen = promise.then
            promise.then = ->
              args = (arg for arg in arguments)
              __notifications.push args[2] if args[2]?
              proxyThen.apply promise, args
            notify: (args...) -> fn args... for fn in __notifications

            # Return the deferred object.
            promise: promise
            resolve: resolve
            reject: reject

          # ## Promise.when
          #
          # See: https://docs.angularjs.org/api/ng/service/$q#when
          Promise.when = (value, handlers...) ->
            Promise.cast(value).then handlers...

          # Proxy Promise.all because Angular supports passing in an object
          # where the values are promises, and the result is an object keyed
          # with the resolved values from the promise.
          originalAll = Promise.all
          Promise.all = (promises) ->

            # Defer to Bluebird if it's an array.
            return originalAll promises if angular.isArray promises

            # If it's not an object, defer to Bluebird (it'll throw).
            return originalAll promises unless angular.isObject promises

            # Track the keys so we can map the values.
            promiseKeys = []
            promiseArray = for key, promise of promises
              promiseKeys.push key
              promise

            originalAll(promiseArray).then (results) ->
              objectResult = {}

              for result, index in results
                objectResult[promiseKeys[index]] = result

              objectResult

          # Return the service.
          Promise

      ]

      # #### Invoke hook `shrubAngularRoutes`.
      #
      # Allow packages to define routes in the Angular application.
      routes = {}
      for route in _.flatten pkgmanProvider.invokeFlat 'shrubAngularRoutes'
        routes[route.path ? path] = route

      # Invoke hook `shrubAngularRoutesAlter`. Allow packages to alter defined
      # routes.
      $injector.invoke(
        injectable, null
        routes: routes
      ) for injectable in pkgmanProvider.invokeFlat 'shrubAngularRoutesAlter'

      for path, route of routes
        do (path, route) ->

          # Wrap the controller so we can provide some automatic behavior.
          routeController = route.controller
          route.controller = [
            '$controller', '$injector', '$q', '$scope'
            ($controller, $injector, $q, $scope) ->

              # Immediately resolve if there's no controller.
              unless routeController?
                return $scope.$emit 'shrub.core.routeRendered'

              # Controllers may return a promise, so wait until any returned
              # value fulfills. If it's not a promise, this will be in the
              # next tick.
              $q.when($injector.invoke(
                routeController, null
                $scope: $scope
                route: route
              )).then(-> $scope.$emit 'shrub.core.routeRendered').done()

          ]

          # Ensure a template exists to make Angular happy.
          route.template ?= ' '

          # Register the path into Angular.
          $routeProvider.when "/#{route.path ? path}", route

      # Create a unique entry point.
      $routeProvider.when '/shrub-angular-entry-point', {}

      # Turn on HTML5 mode: "Real" URLs.
      $locationProvider.html5Mode true
  ]
