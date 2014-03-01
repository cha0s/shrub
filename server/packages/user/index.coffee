
crypto = require 'server/crypto'
passport = require 'passport'
Q = require 'bluebird'

exports.$config = (req) ->
	
	req.user.redactFor(req.user).then (redacted) ->
	
		user: redacted

exports.loadByName = (name) ->
	
	{models: User: User} = require 'server/jugglingdb'
	
	User.findOne where: name: name

exports.$httpInitializer = (req, res, next) ->
	
	{models: User: User} = require 'server/jugglingdb'
	
	LocalStrategy = require("passport-local").Strategy
	
	passport.use new LocalStrategy (username, password, done) ->
		
		(exports.loadByName username).then((user)->
			return Q.resolve() unless user?
			
			if user?
				
				(User.hashPassword password, user.salt).then (passwordHash) ->
					return Q.resolve() unless user.passwordHash is passwordHash
					
					user
				
			else
				
				Q.resolve()
			
		).nodeify done
		
	passport.serializeUser (user, done) -> done null, user.id
	
	passport.deserializeUser (id, done) ->
		
		(User.find id).then((user)->
			
			user
		
		).nodeify done
		
	next()
				
exports.$httpMiddleware = (http) ->
	
	{models: User: User} = require 'server/jugglingdb'
	
	label: 'Load user using passport'
	middleware: [
	
		passport.initialize()
		passport.session()
		(req, res, next) ->
			
			req.user ?= new User()
			
			next()
		
	]

exports.$models = (schema) ->
	
	(require 'client/modules/packages/user').$models schema
	
	User = schema.models['User']
	
	User.randomHash = ->
		
		deferred = Q.defer()
		
		require('crypto').randomBytes 24, (error, buffer) ->
			return deferred.reject error if error?
			
			deferred.resolve require('crypto').createHash('sha512').update(
				schema.settings.cryptoKey
			).update(
				buffer.toString()
			).digest 'hex'
			
		deferred.promise
	
	User.hashPassword = (password, salt) ->
		
		(Q.promisify require('crypto').pbkdf2) password, salt, 20000, 512
		
	redactFor = User::redactFor
	User::redactFor = (user) ->
		
		# Decrypt the e-mail if redacting for the same user.
		redactFor.call(this, user).bind({}).then((@redacted) ->
			return @redacted.email unless user.id?
			return @redacted.email if user.id isnt @redacted.id
			
			crypto.decrypt @redacted.email
		
		).then((email) -> @redacted.email = email
		
		).then -> @redacted
		
exports.$modelsAlter = (require 'client/modules/packages/user').$modelsAlter

exports.$socketMiddleware = ->
	
	{models: User: User} = require 'server/jugglingdb'
	
	label: 'Load user using passport'
	middleware: [
	
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
			
			req.socket.join req.user.name if req.user.id?
			
			next()
	
	]

exports[path] = require "packages/user/#{path}" for path in [
	'forgot', 'login', 'logout', 'register', 'reset'
]
