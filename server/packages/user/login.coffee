
LoginError = (require 'client/modules/packages/user/login').$errorType

exports.$endpoint = (req, fn) ->
	
	switch req.body.method
		
		when 'local'
			
			(req.passport.authenticate 'local', (error, user, info) ->
				return fn error if error?
				return fn new LoginError() unless user
				
				req.login user, (error) ->
					return fn error if error?
					user.redactFor(user).nodeify fn
			
			) req, res = {}
