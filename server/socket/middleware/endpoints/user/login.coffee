
{models: User: User} = require 'server/jugglingdb'

module.exports = (req, data, fn) ->
	
	passport = req._passport.instance
	req.body = data
			
	switch data.method
		
		when 'local'
			
			(passport.authenticate 'local', (error, user, info) ->
				return fn attempted: error.message if error?
				return fn code: 420 unless user
				
				req.login user, (error) ->
					return fn attempted: error.message if error?
					fn null, user
			
			) req, res = {}
