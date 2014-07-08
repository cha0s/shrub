
# # Socket
# 
# Provide an Angular service wrapping Socket.IO.

config = require 'config'
logging = require 'logging'

logger = logging.create 'socket'

# ## Implements hook `service`
exports.$service = -> [
	'$rootScope'
	($rootScope) ->
		
		service = {}
		
		# Be aware: this will throw in unit tests because [global].io won't be
		# available. It must be mocked out.
		return service if 'unit' is config.get 'testMode'

		# `TODO`: Only Socket.IO at the moment.
		socket = io.connect()
		
		# We have to queue emits while not initialized to keep things robust.
		initializedQueue = []
		socket.on 'initialized', =>
			service.emit.apply this, args for args in initializedQueue
		
		# Connection and disconnection.
		service.connect = -> socket.socket.connect()
		service.connected = -> socket.socket.connected
		service.disconnect = -> socket.disconnect()
		
		# ## socket.on
		service.on = (eventName, fn) ->
			
			# We need to digest the scope after the response.
			socket.on eventName, (data) ->
				
				# Log.
				message = "received: #{eventName}"
				message += ", #{JSON.stringify data, null, '  '}" if data?
				logger.debug message
				
				onArguments = arguments
				$rootScope.$apply -> fn.apply socket, onArguments
		
		# ## socket.emit
		service.emit = (eventName, data, fn) ->
			return initializedQueue.push arguments unless service.connected()
		
			# Log.
			message = "sent: #{eventName}"
			message += ", #{JSON.stringify data, null, '  '}" if data?
			logger.debug message
			
			socket.emit eventName, data, (response) ->
				
				# Early out if the client doesn't care about the response.
				return unless fn?
				
				# Log.
				message = "response: #{eventName}"
				message += ", #{
					JSON.stringify response, null, '  '
				}" if response.result? or response.error?
				logger.debug message
				
				# We need to digest the scope after the response.
				$rootScope.$apply -> fn response
		
		$rootScope.$on 'debugLog', (error) -> service.emit 'debugLog', error
		
		service
		
]

# ## Implements hook `serviceMock`
exports.$serviceMock = -> [
	'$q', '$rootScope', '$timeout'
	($q, $rootScope, $timeout) ->
		
		service = {}
		
		onMap = {}
		service.on = (type, fn) -> (onMap[type] ?= []).push fn
		service.stimulateOn = (type, data) ->
			$timeout -> fn data for fn in onMap[type] ? []
			
		emitMap = {}
		service.catchEmit = (type, fn) -> (emitMap[type] ?= []).push fn
		service.emit = (type, data, done) ->
			$timeout -> fn data, done for fn in emitMap[type] ? []
					
		service
		
]
