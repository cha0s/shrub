
audit = require 'audit'
errors = require 'errors'

{Limiter, threshold} = require 'limits'

exports.$endpointAlter = (endpoints) ->

	for route, endpoint of endpoints
		
		do (route, endpoint) ->
		
			if endpoint.limiter?
			
				endpoint.limiter.instance = new Limiter(
					"rpc://#{route}"
					endpoint.limiter.threshold
				)
					
				endpoint.limiter.message ?= "You are doing that too much."
				
				endpoint.validators.push (req, res, next) ->
					
					{instance, message, threshold} = endpoint.limiter
		
					instance.addAndCheckThreshold(audit.keys req).done(
						
						(isLimited) ->
							
							return next errors.instantiate(
								'limiterThreshold'
								message
								threshold.time()
							) if isLimited
							
							next()
							
						(error) -> next error
						
					)
				
exports.$errorType = (require 'client/modules/packages/limiter').$errorType
