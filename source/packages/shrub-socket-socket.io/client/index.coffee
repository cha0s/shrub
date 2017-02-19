# Socket.IO socket

*Provide an Angular service wrapping Socket.IO.*

###### TODO: Need to handle connection errors.

```coffeescript
config = require 'config'
debug = require('debug') 'shrub:socket.io'

Socket = require 'shrub-socket/socket'

exports.Manager = class SocketIoSocket extends Socket

  @$inject = ['$rootScope']
```

## *constructor**

```coffeescript
  constructor: ($rootScope) ->
    super

    @_isConnected = false
    @_$rootScope = $rootScope
    @_socket = io.connect()
```

Queue up any messages to be emitted before initialization completes, and
send them all immediately upon connection.

```coffeescript
    @_initializedQueue = []
    @_socket.on 'initialized', =>
      @emit.apply this, args for args in @_initializedQueue

    @_socket.on 'connect', => @_isConnected = true

    return
```

## SocketIoSocket#disconnect

*Disconnect the socket from the server.*

```coffeescript
  disconnect: -> @_socket.disconnect()
```

## SocketIoSocket#emit

* (String) `eventName` - The name of the event to emit.

* (any) `data` - The event data to emit.

* (optional Function) `fn` - Callback called with whatever the server
returned.

*Emit an event to the server.*

```coffeescript
  emit: (eventName, data, fn) ->
    return @_initializedQueue.push arguments unless @_isConnected
```

Log.

```coffeescript
    message = "sent: #{eventName}"
    message += ", #{JSON.stringify data, null, '  '}" if data?
    debug message

    @_socket.emit eventName, data, (response) =>
```

Early out if the client doesn't care about the response.

```coffeescript
      return unless fn?
```

Log.

```coffeescript
      message = "response: #{eventName}"
      message += ", #{
        JSON.stringify response, null, '  '
      }" if response.result? or response.error?
      debug message
```

Enter Angular scope.

```coffeescript
      @_$rootScope.$apply -> fn response
```

## SocketIoSocket#on

* (String) `eventName` - The name of the event to listen for.

* (optional Function) `fn` - Callback called with the event data.

*Listen for an event.*

```coffeescript
  on: (eventName, fn) ->
```

We need to digest the scope after the response.

```coffeescript
    @_socket.on eventName, (data) =>
```

Log.

```coffeescript
      message = "received: #{eventName}"
      message += ", #{JSON.stringify data, null, '  '}" if data?
      debug message
```

Enter Angular scope.

```coffeescript
      onArguments = arguments
      @_$rootScope.$apply => fn.apply @_socket, onArguments
```
