
nodeCrypto = require 'crypto'
passport = require 'passport'
Promise = require 'bluebird'

crypto = require 'server/crypto'

exports.$auditKeys = (req) ->
	keys = []
	keys.push req.user.id if req.user.id?
	keys

exports.$config = (req) ->
	
	req.user.redactFor(req.user).then (redacted) ->
	
		user: redacted

exports.loadByName = (name) ->
	
	{models: User: User} = require 'server/jugglingdb'
	
	User.findOne where: name: name

exports.$httpInitializer = -> (req, res, next) ->
	
	{models: User: User} = require 'server/jugglingdb'
	
	LocalStrategy = require('passport-local').Strategy
	
	passport.use new LocalStrategy (username, password, done) ->
		
		(exports.loadByName username).then((user)->
			return unless user?
			
			(User.hashPassword password, user.salt).then (passwordHash) ->
				return unless user.passwordHash is passwordHash
				
				user
			
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
		Promise.promisify(nodeCrypto.randomBytes)(24).then (buffer) ->
			nodeCrypto.createHash('sha512').update(
				schema.settings.cryptoKey
			).update(
				buffer.toString()
			).digest 'hex'
	
	User.hashPassword = (password, salt) ->
		Promise.promisify(nodeCrypto.pbkdf2)(
			password, salt, 20000, 512
		)
		
	redactFor = User::redactFor
	User::redactFor = (user) ->
		
		# Decrypt the e-mail if redacting for the same user.
		redactFor.call(this, user).bind({}).then((@redacted) ->
			return null unless @redacted.email?
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
