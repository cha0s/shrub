# Socket

*Manage socket connections.*

```coffeescript
config = require 'config'
```

The socket manager.

```coffeescript
socketManager = null

exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubConfigClient`](../../../hooks#shrubconfigclient)

```coffeescript
  registrar.registerHook 'shrubConfigClient', ->
```

If we're doing end-to-end testing, mock out the socket manager.

```coffeescript
    socketModule = if (config.get 'E2E')?

      'shrub-socket/dummy'

    else

      config.get 'packageConfig:shrub-socket:manager:module'

    manager: module: socketModule
```

#### Implements hook [`shrubCoreBootstrapMiddleware`](../../../hooks#shrubcorebootstrapmiddleware)

```coffeescript
  registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

    label: 'Socket server'
    middleware: [

      (next) ->

        {manager: httpManager} = require 'shrub-http'

        {Manager} = require config.get 'packageConfig:shrub-socket:manager:module'
```

Spin up the socket server, and have it listen on the HTTP server.

```coffeescript
        socketManager = new Manager()
        socketManager.loadMiddleware()
        socketManager.listen httpManager()

        next()

    ]
```

#### Implements hook [`shrubConfigServer`](../../../hooks#shrubconfigserver)

```coffeescript
  registrar.registerHook 'shrubConfigServer', ->
```

Middleware stack dispatched for a socket connection.

```coffeescript
    connectionMiddleware: [
      'shrub-core'
      'shrub-http-express/session'
      'shrub-session'
      'shrub-user'
      'shrub-villiany'
      'shrub-rpc'
    ]
```

Middleware stack dispatched when socket disconnects.

```coffeescript
    disconnectionMiddleware: []

    manager:
```

Module implementing the socket manager. Defaults to socket.io.

```coffeescript
      module: 'shrub-socket-socket.io'
```

#### Implements hook [`shrubReplContext`](../../../hooks#shrubreplcontext)

```coffeescript
  registrar.registerHook 'shrubReplContext', (context) ->
```

Provide the socketManager to REPL.

```coffeescript
    context.socketManager = socketManager
```

## manager

*Get the socket manager.*

```coffeescript
exports.manager = -> socketManager
```
