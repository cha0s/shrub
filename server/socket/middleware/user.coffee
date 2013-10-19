
{models: User: User} = require 'server/jugglingdb'

module.exports.middleware = -> [

	(req, res, next) ->
		
		req.user = (fn) ->
			if req.session?.uid
				User.find req.session.uid, fn
			else
				fn null, new User()
				
		next()
		
]
