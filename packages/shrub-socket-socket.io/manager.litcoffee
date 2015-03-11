# SocketIoManager

*A [Socket.IO](http://socket.io/) implementation of SocketManager.*

    {EventEmitter} = require 'events'

    Promise = null

    config = null
    errors = null
    logging = null

    socketLogger = null

    SocketManager = require '../shrub-socket/manager'

    module.exports = class SocketIoManager extends SocketManager

## *constructor*

      constructor: ->
        super

        Promise ?= require 'bluebird'

        config ?= require 'config'
        errors ?= require 'errors'
        logging ?= require 'logging'

        socketLogger ?= logging.create 'logs/socket.io.log'

        options = config.get 'packageSettings:shrub-socket:manager:options'

Load the adapter.

        @_adapter = switch options?.store ? 'redis'

          when 'redis'

            redis = require 'redis'

            require('socket.io-redis')(
              pubClient: redis.createClient()
              subClient: redis.createClient()
            )

## SocketIoManager#broadcast

* (string) `channel` - The channel to broadcast to.
* (string) `event` - The event to broadcast.
* (any) `data` - The data to broadcast.

*Broadcast data to clients in a room.*

      broadcast: (channel, event, data) ->
        @io.in(channel).emit event, data
        this

## SocketIoManager#channels

* (socket) `socket` - A socket.

*Get a list of channels a socket is in.*

      channels: (socket) -> socket.rooms

## SocketIoManager#clients

* (string) `channel` - The channel to check.

*Get a list of clients in a channel.*

      clients: (channel) ->
        self = this
        new Promise (resolve, reject) ->
          self.io.in(channel).clients (error, clients) ->
            return reject error if error?
            resolve clients

## SocketIoManager#intercom

* (string) `channel` - The channel to broadcast to.
* (string) `event` - The event to broadcast.
* (mixed) `data` - The data to broadcast.

*Broadcast data to server sockets in a room.*

      intercom: (channel, event, data) ->
        @io.in(channel).intercom event, data
        this

## SocketIoManager#listen

* (HttpServer) `http` - The HTTP server to listen on for connections.

*Listen for socket connections coming through the HTTP server.*

      listen: (http) ->

        options = config.get 'packageSettings:shrub-socket:manager:options'

Set up the socket.io server.

        @io = require('socket.io') http.server()

Set the adapter.

        @io.adapter @_adapter if @_adapter?

Authorization.

        @io.use (socket, next) =>

          socket.request.http = http
          socket.request.socket = socket

Connect provides this, it will make middleware (like session) not choke and
die.

          socket.request.originalUrl = socket.request.url

Build a fake response which extends EventEmitter because some connect
middleware (like session) listenes for errors with `on`. Even though they're
never actually emitted, this will make sure nothing breaks.

          res = new class SocketConnectionResponse extends EventEmitter
            constructor: -> super

Dispatch the authorization middleware.

          @_connectionMiddleware.dispatch socket.request, res, (error) ->

If any kind of error was thrown, propagate it.

            return next error if error?

            next()

Connection (post-authorization).

        @io.on 'connection', (socket) =>

Run the disconnection middleware on socket close.

          oncloseProxy = socket.onclose
          socket.onclose = =>
            @_disconnectionMiddleware.dispatch socket.request, null, (error) ->
              socketLogger.error errors.stack error if error?

            oncloseProxy.call socket

Join a '$global' channel.

          socket.join '$global', (error) =>
            return socketLogger.error errors.stack error if error?

Dispatch the connection middleware.

            socket.emit 'initialized'
