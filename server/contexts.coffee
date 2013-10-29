
_ = require 'underscore'
nconf = require 'nconf'
Q = require 'q'

contexts = {}

exports.lookup = (id) -> contexts[id]

exports.add = (id, context, fn) ->
	
	{shrub, window} = context
	
	# Reset the context timeout.
	context.touch = _.debounce(
		-> context.close()
		nconf.get 'contexts:timeout'
	)
	
	# Close the context.
	context.close = (fn) ->
		Q.when(context.promise).then ->
			return unless contexts[id]?
			contexts[id] = null
			
			# Make sure the socket is dead because Contextify will crash if an
			# object is accessed after it is disposed (and a socket will
			# continue to communicate and access 'window' unless we close it).
			shrub.socket.on 'disconnect', ->
				window.close()
				fn?()
			
			shrub.socket.disconnect()
			
	contexts[id] = context
