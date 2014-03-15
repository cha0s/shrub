
_ = require 'underscore'
nconf = require 'nconf'
Promise = require 'bluebird'

contexts = {}

exports.lookup = (id) -> contexts[id]

exports.add = (id, context, fn) ->
	
	{shrub, window} = context
	
	# Reset the context time-to-live.
	context.touch = _.debounce(
		-> context.close()
		nconf.get 'contexts:ttl'
	)
	
	context.pathRedirect = (path) ->
	
		{$route: routes: routes} = shrub
		if routes[path]?
		
			# Does this path redirect? Do an HTTP redirect.
			if routes[path].redirectTo?
				return routes[path].redirectTo
			
		else
			
			match = false
			
			# Check for any regexs.
			for key, route of routes
				if route.regexp?.test path
					
					# TODO need to extract params to build
					# redirectTo, small enough mismatch to ignore
					# for now.
					return
			
			# Otherwise.
			if routes[null]?
				return routes[null].redirectTo
	
	# Close the context.
	context.close = (fn) ->
		Promise.cast(context.promise).then ->
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
