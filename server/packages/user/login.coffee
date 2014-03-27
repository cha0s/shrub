
Promise = require 'bluebird'

errors = require 'errors'

{threshold} = require 'limits'

clientModule = require 'client/modules/packages/user/login'

# ## Implements hook `endpoint`
exports.$endpoint = ->
	
	limiter:
		message: "You are logging in too much."
		threshold: threshold(3).every(30).seconds()

	receiver: (req, fn) ->
		
		passport = req._passport.instance
		
		loginPromise = switch req.body.method
			
			when 'local'
				
				res = {}
				
				deferred = Promise.defer()
				passport.authenticate('local', deferred.callback) req, res, fn
				
				# Log the user in (if it exists), and redact it for the
				# response.
				deferred.promise.bind({}).spread((@user, info) ->
					throw errors.instantiate 'login' unless @user
					
					Promise.promisify(req.login, req) @user
					
				).then -> @user.redactFor @user
				
# } Using nodeify here crashes the app. It may be a bluebird bug.
		
		loginPromise.then((user) -> fn null, user
		).catch fn

# ## Implements hook `transmittableError`
exports.$transmittableError = clientModule.$transmittableError
