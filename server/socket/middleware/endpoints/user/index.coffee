
{models: User: User} = require 'server/jugglingdb'

module.exports = (req, data, fn) ->
	
	if req.user?
		fn null, req.user
	else
		fn null, new User()
