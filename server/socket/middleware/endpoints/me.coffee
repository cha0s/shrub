
{models: User: User} = require 'server/jugglingdb'

module.exports = (req, data, fn) ->
	
	req.user (error, user) ->
		return fn error if error?
		if user.uid
			fn null, user
		else
			fn null, new User()
