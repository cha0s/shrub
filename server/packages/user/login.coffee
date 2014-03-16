
errors = require 'errors'

{threshold} = require 'limits'

exports.$endpoint = ->

	limiter:
		message: "You are logging in too much."
		threshold: threshold(3).every(30).seconds()

	receiver: (req, fn) ->
		
		switch req.body.method
			
			when 'local'
				
				(req.passport.authenticate 'local', (error, user, info) ->
					return fn error if error?
					return fn errors.instantiate 'login' unless user
					
					req.login user, (error) ->
						return fn error if error?
						user.redactFor(user).nodeify fn
				
				) req, res = {}

exports.$errorType = (require 'client/modules/packages/user/login').$errorType
