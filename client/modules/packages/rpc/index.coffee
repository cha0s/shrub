
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
	'$injector', '$q', 'require', 'pkgman', 'socket'
	({invoke}, {defer}, require, pkgman, {emit}) ->
		
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
					deferred.reject errors.unserialize error
				else
					deferred.resolve result
			
			invoke(
				injectable, null
				
				route: route
				data: data
				result: deferred.promise
			
			) for injectable in pkgman.invokeFlat(
				'rpcCall', route, data, deferred.promise
			
			)
				
			deferred.promise
		
		service
		
]
