
exports.$endpoint =
	
	route: 'hangup'
	receiver: (req, fn) ->
		
		contexts = require 'server/contexts'
		
		return fn() unless (context = contexts.lookup req.session.id)?
		context.close fn

exports.$appRun = [
	'$window', 'config', 'comm/rpc'
	($window, config, rpc) ->
	
		# Hang up the socket unless it's the local (Node.js) client.
		unless $window.navigator.userAgent.match /^Node\.js .*$/
			rpc.call 'hangup'

]

exports.$service = [
	'$q', 'require', 'comm/socket'
	($q, require, socket) ->
		
		service = {}
		
		service.call = (route, data) ->
			
			deferred = $q.defer()
			
			socket.emit "rpc://#{route}", data, ({errors, result}) ->
				return deferred.reject new Error(
					require('errors').formatErrors errors
				) if errors?
				
				deferred.resolve result
				
			deferred.promise
		
		service
		
]
