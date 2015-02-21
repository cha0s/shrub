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

* (String) `route` - The RPC endpoint route, e.g. `user.login`.
* (Object) `data` - The data to send to the server.

*Call the server with some data.*

Returns a promise, either resolved with the result of the response
from the server, or rejected with the error from the server.

          service.call = (route, data) ->

            deferred = defer()

            socket.emit "rpc://#{route}", data, ({error, result}) ->
              if error?
                deferred.reject errors.unserialize error
              else
                deferred.resolve result

            invoke(
              injectable, null

              route: route
              data: data
              result: deferred.promise

            ) for injectable in pkgman.invokeFlat 'rpcCall'

            deferred.promise

## rpc.formSubmitHandler

* (String) `route` - The RPC endpoint route, e.g. `user.login`.
* (Function) `fn` - Nodeback called with the RPC response.

*Helper function to call an RPC route with the result of a form submission.*

###### TODO: Shouldn't this just return the promise?

          service.formSubmitHandler = (route, fn) ->

            unless fn?
              fn = route
              route = null

            (values, form) ->

              service.call(
                exports.normalizeRouteName route ? form.key
                values
              ).then(
                (result) -> fn null, result
                (error) -> fn error
              )

          service

      ]

## rpc.normalizeRouteName

* (String) `name` - Route name to normalize.

*Convert a route name to a dotted name. e.g. `some-package/path` ->
`some.package.path`.*

    exports.normalizeRouteName = (name) ->

      i8n = require 'inflection'

      name = i8n.underscore name
      name = i8n.dasherize name.toLowerCase()
      name = i8n.underscore name
      name.replace /[-\/]/g, '.'
