
{models: User: User} = require 'server/jugglingdb'

module.exports.middleware = (http) -> [
	
	(req, res, next) ->
		
		if req.session?.uid?
			
			User.find req.session.uid, (error, user) ->
				next error if error?
				
				req.user = user
				next()
		
		else
		
			req.user = new User()
			next()
	
]
