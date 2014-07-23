
# # Socket.IO socket
# 
# Provide an Angular service wrapping Socket.IO.

config = require 'config'
logging = require 'logging'

logger = logging.create 'socket'

Socket = require 'shrub-socket/socket'

module.exports = class SocketIoSocket extends Socket

	constructor: ($rootScope) ->
		super
		
		@_initializedQueue = []
		@_isConnected = false
		@_$rootScope = $rootScope
		@_socket = io.connect()
		
		@_$rootScope.$on 'shrub.debug.log', (error) =>
			@emit 'shrub.debug.log', errors.serialize error
	
		@_socket.on 'initialized', =>
			@emit.apply @, args for args in @_initializedQueue
				
		@_socket.on 'connect', => @_isConnected = true
		
		return	
	
	emit: (eventName, data, fn) ->
		return @_initializedQueue.push arguments unless @_isConnected
	
		# Log.
		message = "sent: #{eventName}"
		message += ", #{JSON.stringify data, null, '  '}" if data?
		logger.debug message
		
		@_socket.emit eventName, data, (response) =>
			
			# Early out if the client doesn't care about the response.
			return unless fn?
			
			# Log.
			message = "response: #{eventName}"
			message += ", #{
				JSON.stringify response, null, '  '
			}" if response.result? or response.error?
			logger.debug message
			
			# We need to digest the scope after the response.
			@_$rootScope.$apply -> fn response

	on: (eventName, fn) ->
	
		# We need to digest the scope after the response.
		@_socket.on eventName, (data) =>
			
			# Log.
			message = "received: #{eventName}"
			message += ", #{JSON.stringify data, null, '  '}" if data?
			logger.debug message
			
			onArguments = arguments
			@_$rootScope.$apply => fn.apply @_socket, onArguments
	
SocketIoSocket.$inject = ['$rootScope']
			