
$module.service 'rpc', [
	'$q', 'require', 'socket'
	($q, require, socket) ->
		
		@call = (route, data, fn) ->
			
			deferred = $q.defer()
			
			unless fn?
				fn = data
				data = null
			
			socket.emit "rpc://#{route}", data, ({errors, result}) ->
				return deferred.reject new Error(
					require('errors').formatErrors errors
				) if errors?
				deferred.resolve result
				
			deferred.promise
		
		return
		
]
