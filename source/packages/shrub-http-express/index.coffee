# Express

*An [Express](http://expressjs.com/) HTTP server implementation, with
middleware for sessions, routing, logging, etc.*
```coffeescript
config = require 'config'

{routeSentinel} = require './routes'

http = null

express = null
sticky = null

Promise = null

exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubCorePreBootstrap`.
```coffeescript
  registrar.registerHook 'shrubCorePreBootstrap', ->

    http = require 'http'

    express = require 'express'
    sticky = require 'sticky-session'

    Promise = require 'bluebird'
```
#### Implements hook `shrubRpcRoutesAlter`.

Patch in express-specific variables that will be required by middleware.
```coffeescript
  registrar.registerHook 'shrubRpcRoutesAlter', (routes) ->

    expressMiddleware = (req, res, next) ->

      req.headers = req.socket.request.headers
      req.originalUrl = req.socket.request.originalUrl

      next()

    expressMiddleware.weight = -9999

    for path, route of routes

      route.middleware.unshift expressMiddleware

    return

  registrar.recur [
    'errors', 'logger', 'routes', 'session', 'static'
  ]
```
An implementation of [HttpManager](../http/manager) using the Express
framework.
```coffeescript
{Manager: HttpManager} = require '../shrub-http/manager'
exports.Manager = class Express extends HttpManager
```
## *constructor*

*Create the server.*
```coffeescript
  constructor: ->
    super
```
Create the Express instance.
```coffeescript
    @_app = express()
```
Register middleware.
```coffeescript
    @registerMiddleware()

    @_routes = []
```
Spin up an HTTP server.
```coffeescript
    @_server = http.createServer @_app
```
## Express#addRoute

*Add HTTP routes.*
```coffeescript
  addRoute: (route) -> @_routes.push route
```
## Express#cluster

*Spawn workers and tie them together into a cluster.*
```coffeescript
  cluster: ->

    coreConfig = config.get 'packageSettings:shrub-core'
    @_server = sticky(
      num: coreConfig.workers
      trustedAddresses: coreConfig.trustedProxies
      @_server
    )

    return

  initialize: ->
    listenPromise = super
```
Connect (no pun) Express's middleware system to ours.
```coffeescript
    for fn in @_middleware._middleware
      if fn is routeSentinel
        for {verb, path, receiver} in @_routes
          @_app[verb] path, receiver

      else
        @_app.use fn

    return listenPromise
```
## Express#listener

*Listen for HTTP connections.*
```coffeescript
  listener: ->

    new Promise (resolve, reject) =>

      @_server.on 'error', reject

      @_server.once 'listening', =>
        @_server.removeListener 'error', reject
        resolve()
```
} Bind to the listen port.
```coffeescript
      @_server.listen @port()
```
## Express#server

*The node HTTP server instance.*
```coffeescript
  server: -> @_server
```
