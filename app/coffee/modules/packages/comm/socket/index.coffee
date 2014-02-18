
exports.$service = [
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
		
		debugListeners = {}

# Connection and disconnection.
		
		service.connect = -> socket.socket.connect()
		
		service.connected = -> socket.socket.connected

		service.disconnect = -> socket.disconnect()
		
# Proxy for Socket::on, handles invocation of Scope::$apply.
		
		service.on = (eventName, callback) ->
			
			debugListeners["on-#{eventName}"] ?= (->
				socket.on eventName, (data) ->
					console.debug "received: #{eventName}, #{JSON.stringify data, null, '  '}"
			)() if config.get 'debugging'
				
			socket.on eventName, ->
				
				onArguments = arguments
				$rootScope.$apply -> callback.apply socket, onArguments
		
# Proxy for Socket::emit, handles invocation of Scope::$apply.

		service.emit = (eventName, data, callback) ->
			return initializedQueue.push arguments unless service.connected()
			
			if config.get 'debugging'
				console.debug "sent: #{eventName}, #{JSON.stringify data, null, '  '}"
				
			socket.emit eventName, data, ->
				
				return unless callback?
				
				if config.get 'debugging'
					console.debug "data from: #{eventName}, #{JSON.stringify arguments, null, '  '}"
					
				emitArguments = arguments
				$rootScope.$apply -> callback.apply socket, emitArguments
		
		$rootScope.$on 'debugLog', (error) -> service.emit 'debugLog', error
		
		service
		
]

exports.$serviceMock = [
	'$q', '$rootScope', '$timeout'
	($q, $rootScope, $timeout) ->
		
		service = {}
		
		onMap = {}
		service.on = (type, callback) -> (onMap[type] ?= []).push callback
		service.stimulateOn = (type, data) ->
		
			$timeout ->
				for callback in onMap[type] ?= []
					callback data
			
		emitMap = {}
		service.catchEmit = (type, callback) ->
			(emitMap[type] ?= []).push callback
			
		service.emit = (type, data, fn) ->
		
			$timeout ->
				for callback in emitMap[type] ?= []
					callback data, fn
					
		service
		
]


