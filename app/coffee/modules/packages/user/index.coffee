
exports.$endpoint = 

	(req, fn) ->
		
		{models: User: User} = require 'server/jugglingdb'
	
		fn null, if req.user?
			req.user
		else
			new User()

exports[path] = require "packages/user/#{path}" for path in [
	'forgot', 'login', 'logout', 'register', 'reset'
]
