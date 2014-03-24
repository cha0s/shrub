
errors = require 'errors'

exports.$appRun = -> [
	'$window', 'config', 'rpc'
	($window, config, rpc) ->
	
		# Hang up the socket unless it's the local (Node.js) client.
		unless $window.navigator.userAgent.match /^Node\.js .*$/
			rpc.call 'hangup'

]

exports.$service = -> [
	'$injector', '$q', 'require', 'socket'
	($injector, $q, require, socket) ->
		
		service = {}
		
		notifications = null
		
		try

			$injector.invoke [
				'ui/notifications'
				(_notifications_) -> notifications = _notifications_
			]
		
		# It's fine if this fails. 
		catch error
		
		service.call = (route, data) ->
			
			deferred = $q.defer()
			
			socket.emit "rpc://#{route}", data, ({error, result}) ->
				
				if error?
					
					error = errors.caught errors.unserialize error
					
					notifications.add(
						class: 'alert-danger'
						text: errors.message error
					) if notifications?
					
					deferred.reject error
					
				else
					
					deferred.resolve result
				
			deferred.promise
		
		service
		
]
