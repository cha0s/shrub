
# # RPC
# 
# Define an Angular service to issue [remote procedure calls](http://en.wikipedia.org/wiki/Remote_procedure_call#Message_passing).

i8n = require 'inflection'

errors = require 'errors'

exports.pkgmanRegister = (registrar) ->
	
	# ## Implements hook `service`
	registrar.registerHook 'service', -> [
		'$injector', '$q', 'shrub-pkgman', 'shrub-socket'
		({invoke}, {defer}, pkgman, socket) ->
			
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
				
				socket.emit "rpc://#{route}", data, ({error, result}) ->
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
			
			# Handle RPC calls.
			service.formSubmitHandler = (handler) -> [
				
				'form', 'key', 'scope'
				(form, key, scope) ->
				
					dottedFormKey = i8n.underscore key
					dottedFormKey = i8n.dasherize dottedFormKey.toLowerCase()
					dottedFormKey = dottedFormKey.replace '-', '.'
					
					fields = {}
					for name, field of form
						continue if field.type is 'submit'
						fields[name] = scope[name]
					
					service.call(
						dottedFormKey
						fields
					).then(
						(result) -> handler null, result
						(error) -> handler error
					)
			
			]
			
			service
			
	]
