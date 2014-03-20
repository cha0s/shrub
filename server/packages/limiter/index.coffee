
moment = require 'moment'
Promise = require 'bluebird'

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
				
				endpoint.excludeKeys ?= []
					
				endpoint.limiter.message ?= "You are doing that too much."
				
				endpoint.validators.push (req, res, next) ->
					
					{instance, message, threshold} = endpoint.limiter
					
					auditKeys = audit.keys req
					for excludedKey in endpoint.excludeKeys
						delete auditKeys[excludedKey]
						
					keys = ("#{key}:#{value}" for key, value of auditKeys)
					instance.addAndCheckThreshold(keys).done(
						
						(isLimited) ->
							return next() unless isLimited
							
							promise = if req.reportVilliany?
							
								req.reportVilliany(
									endpoint.villianyScore ? 20
									"rpc://#{route}"
								)
								
							else
								
								Promise.resolve false
							
							promise.then (isVillian) ->
								return if isVillian
							
								instance.ttl(keys).then (ttl) ->
								
									next errors.instantiate(
										'limiterThreshold'
										message
										moment().add('seconds', ttl).fromNow()
									)
								
						(error) -> next error
						
					)
				
exports.$errorType = (require 'client/modules/packages/limiter').$errorType
