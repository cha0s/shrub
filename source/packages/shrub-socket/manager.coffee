# SocketManager

```coffeescript
{EventEmitter} = require 'events'
```

This class implements an abstract interface to be implemented by a socket
server (e.g. [Socket.io](source/packages/shrub-socket-socket.io)).

```coffeescript
module.exports = class SocketManager extends EventEmitter
```

## *constructor*

*Create the server.*

```coffeescript
  constructor: ->

    super

    @_connectionMiddleware = null
    @_disconnectionMiddleware = null
```

## SocketManager.AuthorizationFailure

May be thrown from within socket authorization middleware, to denote that
no real error occurred, but authorization failed.

```coffeescript
  class @AuthorizationFailure extends Error
    constructor: (@message) ->
```

## SocketManager#loadMiddleware

*Gather and initialize socket middleware.*

```coffeescript
  loadMiddleware: ->

    middleware = require 'middleware'
```

#### Invoke hook [`shrubSocketConnectionMiddleware`](../../hooks#shrubsocketconnectionmiddleware)

```coffeescript
    @_connectionMiddleware = middleware.fromConfig(
      'shrub-socket:connectionMiddleware'
    )
```

#### Invoke hook [`shrubSocketDisconnectionMiddleware`](../../hooks#shrubsocketdisconnectionmiddleware)

```coffeescript
    @_disconnectionMiddleware = middleware.fromConfig(
      'shrub-socket:disconnectionMiddleware'
    )
```

Ensure any subclass implements these "pure virtual" methods.

```coffeescript
  SocketManager::[method] = (-> throw new ReferenceError(
    "SocketManager::#{method} is a pure virtual method!"
  )) for method in [
    'broadcast', 'channels', 'clients', 'intercom', 'listen'
  ]
```
