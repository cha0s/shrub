
# # RPC
# 
# Define an Angular service to issue [remote procedure calls](http://en.wikipedia.org/wiki/Remote_procedure_call#Message_passing).

errors = require 'errors'

exports.pkgmanRegister = (registrar) ->
	
	# ## Implements hook `service`
	registrar.registerHook 'service', -> [
		'$injector', '$q', 'shrub-pkgman', 'shrub-socket'
		({invoke}, {defer}, pkgman, {emit}) ->
			
			service = {}
			
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
				
				) for injectable in pkgman.invokeFlat 'rpcCall'
					
				deferred.promise
			
			service
			
	]
