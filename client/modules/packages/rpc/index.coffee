
errors = require 'errors'

exports.$appRun = [
	'$window', 'config', 'rpc'
	($window, config, rpc) ->
	
		# Hang up the socket unless it's the local (Node.js) client.
		unless $window.navigator.userAgent.match /^Node\.js .*$/
			rpc.call 'hangup'

]

exports.$service = [
	'$q', 'require', 'socket'
	($q, require, socket) ->
		
		service = {}
		
		service.call = (route, data) ->
			
			deferred = $q.defer()
			
			socket.emit "rpc://#{route}", data, ({error, result}) ->
				
				if error?
				
					deferred.reject errors.unserialize errors.caught error
					
				else
					
					deferred.resolve result
				
			deferred.promise
		
		service
		
]
