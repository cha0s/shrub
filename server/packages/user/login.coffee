
Promise = require 'bluebird'

errors = require 'errors'

{threshold} = require 'limits'

exports.$endpoint = ->
	
	limiter:
		message: "You are logging in too much."
		threshold: threshold(3).every(30).seconds()

	receiver: (req, fn) ->
		
		{passport} = req
		
		loginPromise = switch req.body.method
			
			when 'local'
				
				deferred = Promise.defer()
				
				passport.authenticate('local', deferred.callback)(
					req, res = {}, fn
				)
				
				Promise.settle([
					
					deferred.promise.bind({}).spread((@user, info) ->
						throw errors.instantiate 'login' unless @user
						
						(Promise.promisify req.login, req) @user
						
					).then -> @user.redactFor @user
					
# If no user is found, the rejection will happen a lot sooner than if one is;
# password hashing must be done in the latter case. We'll create an artificial
# floor of 1 second to make it harder for an attacker to tell if a valid
# username was used.

					new Promise (resolve, reject) -> setTimeout resolve, 1000

				]).then ([userPromiseInspector]) ->

					if userPromiseInspector.isFulfilled()
						userPromiseInspector.value()
					else
						throw userPromiseInspector.error()
		
# TODO: Using nodeify here crashes the app. It may be a bluebird bug.
		
#		loginPromise.nodeify fn	
		loginPromise.then(
			(result) -> fn null, result
			(error) -> fn error
		)

exports.$errorType = (require 'client/modules/packages/user/login').$errorType
