
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

exports.initialize = (schema, callback) ->
	
	schema.adapter = new SocketAdapter schema.settings.socket
	
class SocketAdapter
	
	constructor: (@socket) ->
		
	[
		'connect', 'disconnect'
	].forEach (prop) => @::[prop] = (fn) -> @socket.on prop, fn
		
	[
		'define', 'defineForeignKey', 'possibleIndexes', 'transaction'
		'updateIndexes'
	].forEach (prop) => @::[prop] = ->
	
	for prop, i of exports.commands
		do (prop) => @::[prop] = ->
				
			fn = arguments[i]
			arguments[i] = null
			
			@socket.emit(
				"jugglingdb-#{prop}"
				arguments: arguments
				({error, result}) ->
					return fn new Error error if error?
					
					fn null, result
			)
