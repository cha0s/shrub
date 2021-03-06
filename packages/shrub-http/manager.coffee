# # HTTP Manager
#
# *Manage an HTTP server instance.*
Promise = require 'bluebird'

config = require 'config'
pkgman = require 'pkgman'
Promise = require 'bluebird'

middleware = require 'middleware'

httpDebug = require('debug') 'shrub:http'
httpDebugSilly = require('debug') 'shrub-silly:http'
httpMiddlewareDebug = require('debug') 'shrub-silly:http:middleware'

# ## HttpManager
#
# An abstract interface to be implemented by an HTTP server (e.g.
# [Express](source/packages/shrub-http-express)).
exports.Manager = class HttpManager

  # ## *constructor*
  #
  # *Create the server.*
  constructor: ->

    # ###### TODO: Keeping a reference here means HTTP stuff can't be updated at run-time.
    @_config = config.get 'packageConfig:shrub-http'

    @_middleware = null

  # ## HttpManager#initialize
  #
  # *Initialize the server.*
  initialize: ->

    # #### Invoke hook `shrubHttpRoutes`.
    httpDebugSilly '- Registering routes...'
    for routeList in pkgman.invokeFlat 'shrubHttpRoutes', this

      for route in routeList
        route.verb ?= 'get'

        httpDebugSilly "- - #{route.verb.toUpperCase()} #{route.path}"

        @addRoute route
    httpDebugSilly '- Routes registered.'

    # Start listening.
    @listen()

  # ## HttpManager#listen
  #
  # *Listen for HTTP connections.*
  listen: ->
    self = this

    new Promise (resolve, reject) ->

      do tryListener = ->

        self.listener().done(
          resolve

          (error) ->
            return reject error unless 'EADDRINUSE' is error.code

            httpDebug 'HTTP listen target in use... retrying in 2 seconds'
            setTimeout tryListener, 2000

        )

  # ## HttpManager#path
  #
  # *The path where static files are served from.*
  path: -> @_config.path

  # ## HttpManager#listenTarget
  #
  # *Get the target this server (is|will be) listening on.*
  listenTarget: -> @_config.listenTarget

  # ## HttpManager#registerMiddleware
  #
  # *Gather and initialize HTTP middleware.*
  registerMiddleware: ->

    httpMiddlewareDebug '- Loading HTTP middleware...'

    httpMiddleware = @_config.middleware.concat()

    # Make absolutely sure the requests are finalized.
    httpMiddleware.push 'shrub-http'

    # #### Invoke hook `shrubHttpMiddleware`.
    #
    # Invoked every time an HTTP connection is established.
    @_middleware = middleware.fromHook(
      'shrubHttpMiddleware', httpMiddleware, this
    )

    httpMiddlewareDebug '- HTTP middleware loaded.'

  # Ensure any subclass implements these "pure virtual" methods.
  this::[method] = (-> throw new ReferenceError(
    "HttpManager::#{method} is a pure virtual method!"
  )) for method in [
    'addRoute', 'cluster', 'listener', 'server', 'trustProxy'
  ]