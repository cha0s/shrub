# SocketManager

    {EventEmitter} = require 'events'

This class implements an abstract interface to be implemented by a socket
server (e.g. [Socket.io](source/packages/shrub-socket-socket.io)).

    module.exports = class SocketManager extends EventEmitter

## *constructor*

*Create the server.*

      constructor: ->

        super

        @_authorizationMiddleware = null
        @_connectionMiddleware = null
        @_disconnectionMiddleware = null

## SocketManager.AuthorizationFailure

May be thrown from within socket authorization middleware, to denote that no
real error occurred, but authorization failed.

      class @AuthorizationFailure extends Error
        constructor: (@message) ->

## SocketManager#loadMiddleware

*Gather and initialize socket middleware.*

      loadMiddleware: ->

        middleware = require 'middleware'

#### Invoke hook `socketAuthorizationMiddleware`.

        @_authorizationMiddleware = middleware.fromShortName(
          'socket authorization'
          'shrub-socket'
        )

#### Invoke hook `socketConnectionMiddleware`.

        @_connectionMiddleware = middleware.fromShortName(
          'socket connection'
          'shrub-socket'
        )

#### Invoke hook `socketDisconnectionMiddleware`.

        @_disconnectionMiddleware = middleware.fromShortName(
          'socket disconnection'
          'shrub-socket'
        )

Ensure any subclass implements these "pure virtual" methods.

      SocketManager::[method] = (-> throw new ReferenceError(
        "SocketManager::#{method} is a pure virtual method!"
      )) for method in [
        'broadcast', 'channels', 'clients', 'intercom', 'listen'
      ]
