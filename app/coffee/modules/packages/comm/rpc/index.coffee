
exports.$appRun = [
	'$window', 'config', 'comm/rpc'
	($window, config, rpc) ->
	
		# Hang up the socket unless it's the local (Node.js) client.
		rpc.call 'hangup' unless config.userAgent.match /^Node\.js .*$/

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
