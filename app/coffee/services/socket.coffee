
$module.service 'socket', [
	'$rootScope', 'config'
	($rootScope, config) ->
		
# Be aware: this will throw in unit tests because [global].io won't be
# available. It must be mocked out.
	
		socket = io.connect()
		
# Might as well make sure everything's working fine.
		
		debugListeners = {}

# Connection and disconnection.
		
		@connect = -> socket.socket.connect()

		@disconnect = -> socket.disconnect()
		
# Proxy for Socket::on, handles invocation of Scope::$apply.
		
		@on = (eventName, callback) ->
			
			debugListeners["on-#{eventName}"] ?= (->
				socket.on eventName, (data) ->
					console.debug "received: #{eventName}, #{JSON.stringify data, null, '  '}"
			)() if config.get 'debugging'
				
			socket.on eventName, (data) ->
				
				onArguments = arguments
				$rootScope.$apply -> callback.apply socket, onArguments
		
# Proxy for Socket::emit, handles invocation of Scope::$apply.

		@emit = (eventName, data, callback) ->
			
			if config.get 'debugging'
				console.debug "sent: #{eventName}, #{JSON.stringify data, null, '  '}"
				
			socket.emit eventName, data, ->
				
				if config.get 'debugging'
					console.debug "ping back for: #{eventName}"
					
				return unless callback?
				
				if config.get 'debugging'
					console.debug "data from: #{eventName}, #{JSON.stringify arguments, null, '  '}"
					
				emitArguments = arguments
				$rootScope.$apply -> callback.apply socket, emitArguments
		
		$rootScope.$on 'debugLog', (error) => @emit 'debugLog', error
		
		return
		
]
