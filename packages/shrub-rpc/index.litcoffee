# RPC

Framework for communication between client and server through
[RPC](http://en.wikipedia.org/wiki/Remote_procedure_call#Message_passing)

    pkgman = null

RPC endpoint information.

    endpoints = {}

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `preBootstrap`.

      registrar.registerHook 'preBootstrap', ->

        pkgman = require 'pkgman'

#### Implements hook `bootstrapMiddleware`.

      registrar.registerHook 'bootstrapMiddleware', ->

        _ = require 'lodash'
        debug = require('debug') 'shrub-silly:rpc'

        {Middleware} = require 'middleware'

        clientModule = require './client'

        label: 'Bootstrap RPC'
        middleware: [

          (next) ->

#### Invoke hook `endpoint`.

            debug '- Registering RPC endpoints...'
            for path, endpoint of pkgman.invoke 'endpoint'

              endpoint = receiver: endpoint if _.isFunction endpoint

Default the RPC route to the package path, replacing slashes with dots.

              endpoint.route ?= clientModule.normalizeRouteName path
              debug "- - rpc://#{endpoint.route}"

              endpoint.validators ?= []

              endpoints[endpoint.route] = endpoint
            debug '- RPC endpoints registered.'

#### Invoke hook `endpointAlter`.

            pkgman.invoke 'endpointAlter', endpoints

Set up the validators as middleware.

            for route, endpoint of endpoints
              validators = new Middleware()
              for validator in endpoint.validators
                validators.use validator
              endpoint.validators = validators

            next()

        ]

#### Implements hook `socketConnectionMiddleware`.

      registrar.registerHook 'socketConnectionMiddleware', ->

        Promise = require 'bluebird'

        config = require 'config'
        errors = require 'errors'
        logging = require 'logging'

        logger = logging.create 'logs/rpc.log'
        {TransmittableError} = errors

        label: 'Receive and dispatch RPC calls'
        middleware: [

          (req, res, next) ->

            Object.keys(endpoints).forEach (route) ->
              endpoint = endpoints[route]

              req.socket.on "rpc://#{route}", (data, fn) ->

Don't pass req directly, since it can be mutated by routes, and violate other
routes' expectations.

                routeReq = Object.create req
                routeReq.body = data
                routeReq.endpoint = endpoint
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

                endpoint.validators.dispatch routeReq, null, (error) ->
                  return sendErrorToClient error if error?

Receive.

                  endpoint.receiver routeReq, (error, result) ->
                    return sendErrorToClient error if error?

#### Invoke hook `endpointFinished`.

                    Promise.all(
                      pkgman.invokeFlat(
                        'endpointFinished', routeReq, result, req
                      )

                    ).then(
                      -> fn result: result
                      concealErrorFromClient
                    )

            next()

        ]