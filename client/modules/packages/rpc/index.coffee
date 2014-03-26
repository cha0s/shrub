
# # RPC
# 
# Define an Angular service to issue [remote procedure calls](http://en.wikipedia.org/wiki/Remote_procedure_call#Message_passing).

errors = require 'errors'

# ## Implements hook `appRun`
exports.$appRun = -> [
	'$window', 'rpc'
	({navigator}, {call}) ->
	
		# Hang up the socket unless it's the local (Node.js) client.
		# `TODO`: This should be in a client-side `angular` package.
		call 'hangup' unless navigator.userAgent.match /^Node\.js .*$/

]

# ## Implements hook `service`
exports.$service = -> [
	'$injector', '$q', 'require', 'socket'
	({invoke}, {defer}, require, {emit}) ->
		
		service = {}
		
		notifications = null
		
		try

			invoke [
				'ui/notifications'
				(_notifications_) -> notifications = _notifications_
			]
		
		# It's fine if this fails. 
		catch error
		
		# ## rpc.call
		# 
		# Call the server with some data.
		# 
		# * (string) `route` - The RPC endpoint route, e.g. `user.login`.
		# 
		# * (mixed) `data` - The data to send to the server.
		# 
		# Returns a promise, either resolved with the result of the response
		# from the server, or rejected with the error from the server.
		service.call = (route, data) ->
			
			deferred = defer()
			
			emit "rpc://#{route}", data, ({error, result}) ->
				
				if error?
					
					error = errors.unserialize error

					# `TODO`: This should be middleware'd.					
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
