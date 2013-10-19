
$module.service 'rpc', [
	'$q', 'require', 'socket'
	($q, require, socket) ->
		
		@call = (route, data) ->
			
			deferred = $q.defer()
			
			socket.emit "rpc://#{route}", data, ({errors, result}) ->
				return deferred.reject new Error(
					require('errors').formatErrors errors
				) if errors?
				deferred.resolve result
				
			deferred.promise
		
		return
		
]
