# Dummy socket

*Mock out the socket manager.*
```coffeescript
Socket = require 'shrub-socket/socket'

exports.Manager = class DummySocket extends Socket

  constructor: ($timeout) ->
    super

    @_$timeout = $timeout

    @_emitMap = {}
    @_onMap = {}

  catchEmit: (eventName, fn) -> (@_emitMap[eventName] ?= []).push fn

  emit: (eventName, data, done) ->
    @_$timeout => fn data, done for fn in @_emitMap[eventName] ? []

  on: (eventName, fn) -> (@_onMap[eventName] ?= []).push fn

  stimulateOn: (eventName, data) ->
    @_$timeout => fn data for fn in @_onMap[eventName] ? []
```
