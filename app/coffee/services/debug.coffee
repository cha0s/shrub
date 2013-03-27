$module.service 'debug', [
	'$rootScope', 'config'
	($rootScope, config) ->
		
# Catch and log errors.
		
		@intercept = (callback) ->
			
			(error) ->
				
				return $rootScope.$broadcast(
					'debugError'
					error: error.toString()
				) if error?
				
				try
					
					callback.apply(
						callback
						(arguments[i] for i in [1...arguments.length])
					)
					
				catch error
				
					$rootScope.$broadcast(
						'debugError'
						error: error.toString()
					) if error?
		
		return

]
