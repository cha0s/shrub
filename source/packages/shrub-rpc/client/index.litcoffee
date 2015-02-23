# RPC

Define an Angular service to issue [remote procedure calls](http://en.wikipedia.org/wiki/Remote_procedure_call#Message_passing).

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `service`.

      registrar.registerHook 'service', -> [
        '$injector', '$q', 'shrub-pkgman', 'shrub-socket'
        ({invoke}, {defer}, pkgman, socket) ->

          errors = require 'errors'

          service = {}

## rpc.call

* (String) `path` - The RPC route path, e.g. `shrub-user/login`.
* (Object) `data` - The data to send to the server.

*Call the server with some data.*

Returns a promise, either resolved with the result of the response
from the server, or rejected with the error from the server.

          service.call = (path, data) ->

            deferred = defer()

            socket.emit "rpc://#{path}", data, ({error, result}) ->
              if error?
                deferred.reject errors.unserialize error
              else
                deferred.resolve result

            invoke(
              injectable, null

              route: path
              data: data
              result: deferred.promise

            ) for injectable in pkgman.invokeFlat 'rpcCall'

            deferred.promise

## rpc.formSubmitHandler

* (String) `path` - The RPC route path, e.g. `shrub-user/login`.
* (Function) `fn` - Nodeback called with the RPC response.

*Helper function to call an RPC route with the result of a form submission.*

          service.formSubmitHandler = (path, fn) ->

            unless fn?
              fn = path
              path = null

            (values, form) ->

              service.call(path ? form.key, values).then(
                (result) -> fn null, result
              ).catch (error) -> fn error

          service

      ]
