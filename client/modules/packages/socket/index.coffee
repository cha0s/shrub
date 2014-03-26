
# # Socket
# 
# Provide an Angular service wrapping Socket.IO.
# `TODO`: Only Socket.IO at the moment.

# ## Implements hook `service`
exports.$service = -> [
	'$rootScope', 'config'
	($rootScope, config) ->
		
		service = {}
		
		# Be aware: this will throw in unit tests because [global].io won't be
		# available. It must be mocked out.
		return service if 'unit' is config.get 'testMode'
		socket = io.connect()
		
		# We have to queue emits while not initialized to keep things robust.
		initializedQueue = []
		socket.on 'initialized', =>
			service.emit.apply this, args for args in initializedQueue
		
		# Might as well make sure everything's working fine.
		# `TODO`: Remove after client logging.
		debugListeners = {}

		# Connection and disconnection.
		service.connect = -> socket.socket.connect()
		service.connected = -> socket.socket.connected
		service.disconnect = -> socket.disconnect()
		
		# ## socket.on
		service.on = (eventName, fn) ->
			
			# `TODO`: Remove after client logging.
			debugListeners["on-#{eventName}"] ?= (->
				socket.on eventName, (data) ->
					console.debug "received: #{
						eventName
					}, #{
						JSON.stringify data, null, '  '
					}"
			)() if config.get 'debugging'
				
			# We need to digest the scope after the response.
			socket.on eventName, ->
				onArguments = arguments
				$rootScope.$apply -> fn.apply socket, onArguments
		
		# ## socket.emit
		service.emit = (eventName, data, fn) ->
			return initializedQueue.push arguments unless service.connected()
			
			# `TODO`: Remove after client logging.
			if config.get 'debugging'
				console.debug "sent: #{
					eventName
				}, #{
					JSON.stringify data, null, '  '
				}"
				
			socket.emit eventName, data, ->
				
				# Early out if the client doesn't care about the response.
				return unless fn?
				
				# `TODO`: Remove after client logging.
				if config.get 'debugging'
					console.debug "data from: #{
						eventName
					}, #{
						JSON.stringify arguments, null, '  '
					}"
					
				# We need to digest the scope after the response.
				emitArguments = arguments
				$rootScope.$apply -> fn.apply socket, emitArguments
		
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