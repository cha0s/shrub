
# # Dummy socket
# 
# Provide an Angular service wrapping Socket.IO.

config = require 'config'
logging = require 'logging'

logger = logging.create 'socket'

Socket = require 'shrub-socket/socket'

module.exports = class DummySocket extends Socket

	constructor: ($q, $rootScope, $timeout) ->
		super
		
		@_$q = $q
		@_$rootScope = $rootScope
		@_$timeout = $timeout
		
		@_emitMap = {}
		@_onMap = {}

	catchEmit: (eventName, fn) -> (@_emitMap[eventName] ?= []).push fn
		
	emit: (eventName, data, done) ->
		@_$timeout => fn data, done for fn in @_emitMap[eventName] ? []

	on: (eventName, fn) -> (@_onMap[eventName] ?= []).push fn
	
	stimulateOn: (eventName, data) ->
		@_$timeout => fn data for fn in @_onMap[eventName] ? []
