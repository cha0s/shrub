
###

Socket.IO adapter proxy for [JugglingDB](https://github.com/1602/jugglingdb).

This adapter forwards all adapter commands through a socket, to be run by the
database server.

###

# The index where the callback function goes.
exports.commands =

	all: 2
	count: 1
	create: 2
	destroy: 2
	destroyAll: 1
	exists: 2
	find: 2
	save: 2
	updateAttributes: 3
	updateOrCreate: 2
	
class SocketAdapter
	
	constructor: (@socket, @callback) ->
	
	# When the socket connects, the callback passed to connect() will be
	# called, signalling connection.
	connect: (fn) -> @socket.on 'initialized', fn
	
	# Disconnect the socket and call back when it's disconnected.
	disconnect: (fn) ->
		@socket.on 'disconnect', fn
		@socket.disconnect()
	
	# These adapter methods aren't necessary to run on the client. They are
	# responsible for underlying schema management and only make sense when
	# the adapter is actually touching the database e.g. server-side.
	[
		'define', 'defineForeignKey', 'possibleIndexes', 'updateIndexes'
	].forEach (prop) => @::[prop] = ->
	
	# I'm not sure about this one though. Redis adapter doesn't support
	# transactions, but some might? This method will need to be
	# figured out/supported eventually.
	transaction: ->
	
	# Create a method for each adapter command.
	for prop, i of exports.commands
		
		do (prop, i) => @::[prop] = ->
			
			# Pluck out the callback passed in; we won't try to send it to the
			# server.
			fn = arguments[i]
			arguments[i] = null
			
			# Emit the command with all the arguments intact.
			@socket.emit(
				"jugglingdb-#{prop}"
				arguments: arguments
				
				# Back from the server: Return the error or result.
				({error, result}) ->
					return fn new Error error if error?
					fn null, result
			)

# Initialization method; instantiate the SocketAdapter.
exports.initialize = (schema, callback) ->
	schema.adapter = new SocketAdapter schema.settings.socket, callback
