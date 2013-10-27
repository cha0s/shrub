
{models: User: User} = require 'server/jugglingdb'

module.exports = (req, data, fn) ->
	
	req.logout()
	fn null, new User()
