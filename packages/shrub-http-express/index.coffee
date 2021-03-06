# # Express
#
# *An [Express](http://expressjs.com/) HTTP server implementation, with
# middleware for sessions, routing, logging, etc.*
config = require 'config'

{routeSentinel} = require './routes'

http = null

express = null
sticky = null

Promise = null

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubCorePreBootstrap`.
  registrar.registerHook 'shrubCorePreBootstrap', ->

    http = require 'http'

    express = require 'express'
    sticky = require 'sticky-session'

    Promise = require 'bluebird'

  # #### Implements hook `shrubRpcRoutesAlter`.
  #
  # Patch in express-specific variables that will be required by middleware.
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

# An implementation of [HttpManager](../http/manager) using the Express
# framework.
{Manager: HttpManager} = require '../shrub-http/manager'
exports.Manager = class Express extends HttpManager

  # ## *constructor*
  #
  # *Create the server.*
  constructor: ->
    super

    # Create the Express instance.
    @_app = express()

    # Register middleware.
    @registerMiddleware()

    @_routes = []

    # Spin up an HTTP server.
    @_server = http.createServer @_app

  # ## Express#addRoute
  #
  # *Add HTTP routes.*
  addRoute: (route) -> @_routes.push route

  # ## Express#cluster
  #
  # *Spawn workers and tie them together into a cluster.*
  cluster: ->

    coreConfig = config.get 'packageConfig:shrub-core'
    @_server = sticky(
      num: coreConfig.workers
      trustedAddresses: coreConfig.trustedProxies
      @_server
    )

    return

  initialize: ->
    listenPromise = super

    # Connect (no pun) Express's middleware system to ours.
    for fn in @_middleware._middleware
      if fn is routeSentinel
        for {verb, path, receiver} in @_routes
          @_app[verb] path, receiver

      else
        @_app.use fn

    return listenPromise

  # ## Express#listener
  #
  # *Listen for HTTP connections.*
  listener: ->

    new Promise (resolve, reject) =>

      @_server.on 'error', reject

      @_server.once 'listening', =>
        @_server.removeListener 'error', reject
        resolve()

      # Bind to the listen target.
      listenTarget = @listenTarget()
      listenTarget = [listenTarget] unless Array.isArray listenTarget
      @_server.listen listenTarget...

  # ## Express#server
  #
  # *The node HTTP server instance.*
  server: -> @_server

  # ## Express#trustProxy
  #
  # *Set IP addresses as trusted proxies.*
  trustProxy: (proxyList) -> @_app.set 'trust proxy', proxyList
