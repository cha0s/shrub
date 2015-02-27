# RPC

Framework for communication between client and server through
[RPC](http://en.wikipedia.org/wiki/Remote_procedure_call#Message_passing)

    pkgman = null

RPC route information.

    routes = {}

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubCorePreBootstrap`.

      registrar.registerHook 'shrubCorePreBootstrap', ->

        pkgman = require 'pkgman'

#### Implements hook `shrubCoreBootstrapMiddleware`.

      registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

        _ = require 'lodash'
        debug = require('debug') 'shrub-silly:rpc'

        {Middleware} = require 'middleware'

        clientModule = require './client'

        label: 'Bootstrap RPC'
        middleware: [

          (next) ->

#### Invoke hook `shrubRpcRoutes`.

            debug '- Registering RPC routess...'
            for route in _.flatten pkgman.invokeFlat 'shrubRpcRoutes'

Default the RPC route to the package path, replacing slashes with dots.

              debug "- - rpc://#{route.path}"

              route.validators ?= []

              routes[route.path] = route
            debug '- RPC routes registered.'

#### Invoke hook `shrubRpcRoutesAlter`.

            pkgman.invoke 'shrubRpcRoutesAlter', routes

Set up the validators as middleware.

            for path, route of routes
              validators = new Middleware()
              for validator in route.validators
                validators.use validator
              route.validators = validators

            next()

        ]

#### Implements hook `shrubSocketConnectionMiddleware`.

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

            Object.keys(routes).forEach (path) ->
              route = routes[path]

              req.socket.on "rpc://#{path}", (data, fn) ->

Don't pass req directly, since it can be mutated by routes, and violate other
routes' expectations.

                routeReq = Object.create req
                routeReq.body = data
                routeReq.route = route

Send an error to the client.

                emitError = (error) -> fn error: errors.serialize error

Log an error without transmitting it.

                logError = (error) -> logger.error errors.stack error

Send an error to the client, but don't notify them of the real underlying
issue.

                concealErrorFromClient = (error) ->

                  emitError new Error 'Please try again later.'
                  logError error

Transmit the error as it is directly to the client.

                sendErrorToClient = (error) ->
                  emitError error

Log the full error stack, because it might help track down any problem.

                  logError error if do ->

Unknown errors.

                    unless error instanceof TransmittableError
                      return true

If we're not running in production.

                    if 'production' isnt config.get 'NODE_ENV'
                      return true

Validate.

                route.validators.dispatch routeReq, null, (error) ->
                  return sendErrorToClient error if error?

Receive.

                  route.receiver routeReq, (error, result) ->
                    return sendErrorToClient error if error?

#### Invoke hook `shrubRpcRouteFinish`.

                    Promise.all(
                      pkgman.invokeFlat(
                        'shrubRpcRouteFinish', routeReq, result, req
                      )

                    ).then(
                      -> fn result: result
                      concealErrorFromClient
                    )

            next()

        ]
