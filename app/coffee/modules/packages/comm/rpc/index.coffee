
exports.$service = [
	'$q', '$window', 'require', 'comm/socket'
	($q, $window, require, socket) ->
		
		@call = (route, data) ->
			
			deferred = $q.defer()
			
			socket.emit "rpc://#{route}", data, ({errors, result}) ->
				return deferred.reject new Error(
					require('errors').formatErrors errors
				) if errors?
				
				deferred.resolve result
				
			deferred.promise
		
		# Hang up the socket unless it's the local (Node.js) client.
		# TODO do this through config, from server-side
		@call 'hangup' unless $window.navigator.userAgent.match /^Node\.js .*$/
		
		return
		
]
