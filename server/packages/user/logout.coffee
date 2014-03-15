
exports.$endpoint = -> (req, fn) ->
	
	{models: User: User} = require 'server/jugglingdb'
	
	req.logout()
	
	req.user = new User()
	
	fn()
