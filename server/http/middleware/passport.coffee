
crypto = require 'server/crypto'
passport = require 'passport'
{models: User: User} = require 'server/jugglingdb'

LocalStrategy = require("passport-local").Strategy

passport.use new LocalStrategy (username, password, done) ->
	
	filter = where: name: username
	
	User.findOne filter, (error, user) ->
		return done error if error?
		
		if user?
			
			User.hashPassword password, user.salt, (error, passwordHash) ->
				return done error if error?
				return done() unless user.passwordHash is passwordHash
				
				crypto.decrypt user.email, (error, decryptedEmail) ->
					return done error if error?
					
					user.email = decryptedEmail
				
					done null, user.redact()
		
		else
			
			done()

passport.serializeUser (user, done) -> done null, user.id

passport.deserializeUser (id, done) ->
	
	User.find id, (error, user) ->
		return done error if error?
		
		crypto.decrypt user.email, (error, decryptedEmail) ->
			return done error if error?
			
			user.email = decryptedEmail
		
			done null, user.redact()

module.exports.middleware = (http) -> [
	passport.initialize()
	passport.session()
]
