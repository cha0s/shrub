# HTTP Manager

*Manage an HTTP server instance.*

###### TODO: Rename to AbstractHttp

    Promise = require 'bluebird'

    config = require 'config'
    pkgman = require 'pkgman'
    Promise = require 'bluebird'

    middleware = require 'middleware'

    httpDebug = require('debug') 'shrub:http'
    httpDebugSilly = require('debug') 'shrub-silly:http'
    httpMiddlewareDebug = require('debug') 'shrub-silly:http:middleware'

## HttpManager

An abstract interface to be implemented by an HTTP server (e.g.
[Express](source/packages/shrub-http-express)).

    exports.Manager = class HttpManager

## *constructor*

*Create the server.*

      constructor: ->

###### TODO: Keeping a reference here means HTTP stuff can't be updated at run-time.

        @_config = config.get 'packageSettings:shrub-http'

        @_middleware = null

## .initialize

*Initialize the server.*

      initialize: ->

#### Invoke hook `httpRoutes`.

Allows packages to specify HTTP routes. Implementations should return an array
of route specifications. See
[shrub-example's implementation]
(/packages/shrub-example/index.coffee#implementshookhttproutes) as an example.

        httpDebugSilly '- Registering routes...'
        for routeList in pkgman.invokeFlat 'httpRoutes', this

          for route in routeList
            route.verb ?= 'get'

            httpDebugSilly "- - #{route.verb.toUpperCase()} #{route.path}"

            @addRoute route
        httpDebugSilly '- Routes registered.'

#### Invoke hook `httpInitializing`.

Invoked before the server is bound on the listening port.

###### TODO: This goes away after confirming socket can bind after server is listening.

        pkgman.invoke 'httpInitializing', this

Start listening.

        @listen()

## HttpManager#listen

*Listen for HTTP connections.*

      listen: ->
        self = this

        new Promise (resolve, reject) ->

          do tryListener = ->

            self.listener().done(
              resolve

              (error) ->
                return reject error unless 'EADDRINUSE' is error.code

                httpDebug 'HTTP port in use... retrying in 2 seconds'
                setTimeout tryListener, 2000

            )

## HttpManager#path

*The path where static files are served from.*

###### TODO: Shouldn't this be gotten from config?

      path: -> @_config.path

## HttpManager#port

*Get the port this server (is|will be) listening on.*

###### TODO: Shouldn't this be gotten from config?

      port: -> @_config.port

## HttpManager#registerMiddleware

*Gather and initialize HTTP middleware.*

      registerMiddleware: ->

        httpMiddlewareDebug '- Loading HTTP middleware...'

        httpMiddleware = @_config.middleware.concat()
        httpMiddleware.push 'shrub-http'

#### Invoke hook `httpMiddleware`.

Invoked every time an HTTP connection is established.

        @_middleware = middleware.fromHook(
          'httpMiddleware', httpMiddleware, this
        )

        httpMiddlewareDebug '- HTTP middleware loaded.'

Ensure any subclass implements these "pure virtual" methods.

      this::[method] = (-> throw new ReferenceError(
        "HttpManager::#{method} is a pure virtual method!"
      )) for method in [
        'addRoute', 'cluster', 'listener', 'server'
      ]
