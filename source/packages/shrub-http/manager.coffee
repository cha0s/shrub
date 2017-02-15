# HTTP Manager

*Manage an HTTP server instance.*

###### TODO: Rename to AbstractHttp
```coffeescript
Promise = require 'bluebird'

config = require 'config'
pkgman = require 'pkgman'
Promise = require 'bluebird'

middleware = require 'middleware'

httpDebug = require('debug') 'shrub:http'
httpDebugSilly = require('debug') 'shrub-silly:http'
httpMiddlewareDebug = require('debug') 'shrub-silly:http:middleware'
```
## HttpManager

An abstract interface to be implemented by an HTTP server (e.g.
[Express](source/packages/shrub-http-express)).
```coffeescript
exports.Manager = class HttpManager
```
## *constructor*

*Create the server.*
```coffeescript
  constructor: ->
```
###### TODO: Keeping a reference here means HTTP stuff can't be updated at run-time.
```coffeescript
    @_config = config.get 'packageSettings:shrub-http'

    @_middleware = null
```
## HttpManager#initialize

*Initialize the server.*
```coffeescript
  initialize: ->
```
#### Invoke hook `shrubHttpRoutes`.
```coffeescript
    httpDebugSilly '- Registering routes...'
    for routeList in pkgman.invokeFlat 'shrubHttpRoutes', this

      for route in routeList
        route.verb ?= 'get'

        httpDebugSilly "- - #{route.verb.toUpperCase()} #{route.path}"

        @addRoute route
    httpDebugSilly '- Routes registered.'
```
Start listening.
```coffeescript
    @listen()
```
## HttpManager#listen

*Listen for HTTP connections.*
```coffeescript
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
```
## HttpManager#path

*The path where static files are served from.*
```coffeescript
  path: -> @_config.path
```
## HttpManager#port

*Get the port this server (is|will be) listening on.*
```coffeescript
  port: -> @_config.port
```
## HttpManager#registerMiddleware

*Gather and initialize HTTP middleware.*
```coffeescript
  registerMiddleware: ->

    httpMiddlewareDebug '- Loading HTTP middleware...'

    httpMiddleware = @_config.middleware.concat()
```
Make absolutely sure the requests are finalized.
```coffeescript
    httpMiddleware.push 'shrub-http'
```
#### Invoke hook `shrubHttpMiddleware`.

Invoked every time an HTTP connection is established.
```coffeescript
    @_middleware = middleware.fromHook(
      'shrubHttpMiddleware', httpMiddleware, this
    )

    httpMiddlewareDebug '- HTTP middleware loaded.'
```
Ensure any subclass implements these "pure virtual" methods.
```coffeescript
  this::[method] = (-> throw new ReferenceError(
    "HttpManager::#{method} is a pure virtual method!"
  )) for method in [
    'addRoute', 'cluster', 'listener', 'server'
  ]
```
