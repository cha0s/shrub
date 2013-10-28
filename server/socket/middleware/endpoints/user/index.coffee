
{models: User: User} = require 'server/jugglingdb'

module.exports = (req, data, fn) ->
	
	fn null, if req.user?
		req.user
	else
		new User()
