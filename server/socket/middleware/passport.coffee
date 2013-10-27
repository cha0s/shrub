
passport = require 'passport'

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
]
