
passport = require 'passport'
{models: User: User} = require 'server/jugglingdb'

LocalStrategy = require("passport-local").Strategy

passport.use new LocalStrategy((username, password, done) ->
	
	filter = where: name: username
	
	User.findOne filter, (error, user) ->
		return done error if error?
		
		if user?
			
			return done() unless true#user.passwordHash is User.hashPassword password
			
			done null, user
		
		else
			
			done()
	
)

passport.serializeUser (user, done) -> done null, user.id

passport.deserializeUser (id, done) ->
	
	User.find id, (error, user) ->
		return done error if error?
		done null, user

module.exports.middleware = (http) -> [
	passport.initialize()
	passport.session()
]
