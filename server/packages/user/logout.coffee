
{models: User: User} = require 'server/jugglingdb'

exports.$endpoint = (req, fn) ->
	
	req.logout()
	
	req.user = new User()
	
	fn()
