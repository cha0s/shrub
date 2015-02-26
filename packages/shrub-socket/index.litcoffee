# Socket

*Manage socket connections.*

    config = require 'config'

The socket manager.

    socketManager = null

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubConfigClient`.

      registrar.registerHook 'shrubConfigClient', ->

If we're doing end-to-end testing, mock out the socket manager.

        socketModule = if (config.get 'E2E')?

          'shrub-socket/dummy'

        else

          config.get 'packageSettings:shrub-socket:manager:module'

        manager: module: socketModule

#### Implements hook `shrubCoreBootstrapMiddleware`.

      registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

        label: 'Socket server'
        middleware: [

          (next) ->

            {manager: httpManager} = require 'shrub-http'

            {Manager} = require config.get 'packageSettings:shrub-socket:manager:module'

Spin up the socket server, and have it listen on the HTTP server.

            socketManager = new Manager()
            socketManager.loadMiddleware()
            socketManager.listen httpManager()

            next()

        ]

#### Implements hook `shrubConfigServer`.

      registrar.registerHook 'shrubConfigServer', ->

Middleware stack dispatched to authorize or reject a socket connection.

        authorizationMiddleware: [
          'shrub-core'
          'shrub-http-express/session'
          'shrub-user'
          'shrub-audit'
          'shrub-villiany'
        ]

Middleware stack dispatched once a socket connection is authorized.

        connectionMiddleware: [
          'shrub-session'
          'shrub-user'
          'shrub-rpc'
        ]

Middleware stack dispatched when socket disconnects.

        disconnectionMiddleware: []

        manager:

Module implementing the socket manager. Defaults to socket.io.

          module: 'shrub-socket-socket.io'

#### Implements hook `shrubReplContext`.

      registrar.registerHook 'shrubReplContext', (context) ->

Provide the socketManager to REPL.

        context.socketManager = socketManager

## manager

*Get the socket manager.*

    exports.manager = -> socketManager
