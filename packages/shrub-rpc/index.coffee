# # RPC
#
# Framework for communication between client and server through
# [RPC](http://en.wikipedia.org/wiki/Remote_procedure_call#Message_passing)
{EventEmitter} = require 'events'
{IncomingMessage} = require 'http'

pkgman = null

# RPC route information.
routes = {}

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubCorePreBootstrap`.
  registrar.registerHook 'shrubCorePreBootstrap', ->

    pkgman = require 'pkgman'

  # #### Implements hook `shrubCoreBootstrapMiddleware`.
  registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

    _ = require 'lodash'
    debug = require('debug') 'shrub-silly:rpc'

    {Middleware} = require 'middleware'

    clientModule = require './client'

    label: 'Bootstrap RPC'
    middleware: [

      (next) ->

        # #### Invoke hook `shrubRpcRoutes`.
        debug '- Registering RPC routess...'
        for route in _.flatten pkgman.invokeFlat 'shrubRpcRoutes'

          debug route.path

          # Normalize middleware to array form.
          route.middleware ?= []
          if 'function' is typeof route.middleware
            route.middleware = [route.middleware]

          routes[route.path] = route
        debug '- RPC routes registered.'

        # #### Invoke hook `shrubRpcRoutesAlter`.
        pkgman.invoke 'shrubRpcRoutesAlter', routes

        # Set up the middleware dispatcher.
        for path, route of routes
          route.dispatcher = new Middleware()

          fn.weight ?= index for fn, index in route.middleware

          sortedMiddleware = route.middleware.sort (l, r) ->
            (l.weight ? 0) - (r.weight ? 0)

          route.dispatcher.use fn for fn in sortedMiddleware

        next()

    ]

  # #### Implements hook `shrubSocketConnectionMiddleware`.
  registrar.registerHook 'shrubSocketConnectionMiddleware', ->

    Promise = require 'bluebird'

    config = require 'config'
    errors = require 'errors'
    logging = require 'logging'

    logger = logging.create 'logs/rpc.log'
    {TransmittableError} = errors

    label: 'Receive and dispatch RPC calls'
    middleware: [

      (req, res, next) ->

        # Log an error without transmitting it.
        logError = (error) -> logger.error errors.stack error

        # Hub for RPC calls. Dispatch routes.
        req.socket.on 'shrub-rpc', ({path, data}, fn) ->
          unless (route = routes[path])?
            return logError new Error "Unknown route called: #{path}"

          # Don't pass req directly, since it can be mutated by routes, and
          # violate other routes' expectations.
          routeReq = new IncomingMessage req.socket.conn
          routeReq.body = data
          routeReq.route = route
          routeReq.socket = req.socket

          routeRes = new class RpcRouteResponse extends EventEmitter

            constructor: ->
              super

              @data = {}
              @error = null
              @headers = {}

            getHeader: (key) -> @headers[key]

            setHeader: (key, value) -> @headers[key] = value

            setError: (@error) -> return this

            end: (data) ->

              @write data

              return fn error: errors.serialize @error if @error?
              fn result: @data

            write: (data) -> @data[k] = v for own k, v of data

            writeHead: (code, headers) ->
              @headers[k] = v for k, v of headers

          # Send an error to the client.
          emitError = (error) -> routeRes.setError(error).end()

          # Send an error to the client, but don't notify them of the real
          # underlying issue.
          concealErrorFromClient = (error) ->

            emitError new Error 'Please try again later.'
            logError error

          # Transmit the error as it is directly to the client.
          sendErrorToClient = (error) ->
            emitError error

            # Log the full error stack, because it might help track down any
            # problem.
            logError error if do ->

              # Unknown errors.
              unless error instanceof TransmittableError
                return true

              # If we're not running in production.
              if 'production' isnt config.get 'NODE_ENV'
                return true

          # Dispatch the route.
          route.dispatcher.dispatch routeReq, routeRes, (error) ->
            sendErrorToClient error if error?

        next()

    ]

# ### spliceRouteMiddleware
#
# * (Object) `route` - The RPC route definition object.
#
# * (String) `key` - The key used by RPC routes to be replaced with
# middleware.
#
# * (Function Array) `middleware` - The middleware to be spliced in.
#
# *Splice middleware functions in place of a key.*
#
# Some packages define RPC route middleware that can be included as a string
# (e.g. `'shrub-user'`). This function will splice in an array of middleware
# where a placeholder key specifies.
exports.spliceRouteMiddleware = (route, key, middleware) ->
  return unless ~(index = route.middleware.indexOf key)

  l = route.middleware.slice 0, index
  r = route.middleware.slice index + 1

  route.middleware = l.concat middleware, r

  return