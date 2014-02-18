
passport = require 'passport'

{models: User: User} = require 'server/jugglingdb'

module.exports.middleware = (http) -> [
	
	(req, res, next) ->
		
		req[method] = require('http').IncomingMessage.prototype[method] for method in [
			'login', 'logIn'
			'logout', 'logOut'
			'isAuthenticated', 'isUnauthenticated'
		]
			
		next()
		
	passport.initialize()
	passport.session()
	
	(req, res, next) ->
		
		req.passport = req._passport.instance
		
		req.user ?= new User()
		
		next()
	
]
