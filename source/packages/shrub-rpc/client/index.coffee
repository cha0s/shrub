# RPC

Define an Angular service to issue [remote procedure
calls](http://en.wikipedia.org/wiki/Remote_procedure_call#Message_passing).

```coffeescript
exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubAngularService`](../../../hooks#shrubangularservice)

```coffeescript
  registrar.registerHook 'shrubAngularService', -> [
    '$injector', '$q', 'shrub-pkgman', 'shrub-socket'
    ({invoke}, {defer}, pkgman, socket) ->

      errors = require 'errors'

      service = {}
```

## rpc.call

* (String) `path` - The RPC route path, e.g. `shrub-user/login`.

* (Object) `data` - The data to send to the server.

*Call the server with some data.* Returns a promise, either resolved
with the result of the response from the server, or rejected with the
error from the server.

```coffeescript
      service.call = (path, data) ->

        deferred = defer()

        socket.emit(
          'shrub-rpc'
          path: path, data: data
          ({error, result}) ->
            return deferred.reject errors.unserialize error if error?
            deferred.resolve result
        )
```

#### Invoke hook [`shrubRpcCall`](../../../hooks#shrubrpccall)

```coffeescript
        invoke(
          injectable, null

          route: path
          data: data
          result: deferred.promise

        ) for injectable in pkgman.invokeFlat 'shrubRpcCall'

        deferred.promise
```

## rpc.on

* (String) `eventName` - The name of the event to listen for.

* (optional Function) `fn` - Callback called with the event data.

*Listen for an event.* Proxies directly to `socket.on`.

```coffeescript
      service.on = (eventName, fn) -> socket.on eventName, fn
```

## rpc.formSubmitHandler

* (String) `path` - The RPC route path, e.g. `shrub-user/login`.

* (Function) `fn` - Nodeback called with the RPC response.

*Helper function to call an RPC route with the result of a form
submission.*

```coffeescript
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
```
