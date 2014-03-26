
# # User
# 
# User oprations. 

passport = require 'passport'
Promise = require 'bluebird'

crypto = require 'server/crypto'

clientModule = require 'client/modules/packages/user'

# ## Implements hook `auditKeys`
exports.$auditKeys = (req) ->

	# User (ID).
	user: req.user.id if req.user?.id?

# ## Implements hook `config`
exports.$config = (req) ->
	
	# Send a redacted version of the request user.
	req.user.redactFor(req.user).then (redacted) -> user: redacted

# ## Implements hook `httpMiddleware`
exports.$httpMiddleware = (http) ->
	
	{models: User: User} = require 'server/jugglingdb'
	
	label: 'Load user using passport'
	middleware: [
		
		# Passport middleware.
		passport.initialize()
		passport.session()
		
		# Set the user into the request.
		(req, res, next) ->
			
			if req.user?
			
				req.user.logout = ->
					
					req.logout()
					req.user = new User()
					
					Promise.resolve req.user
					
			else
			
				req.user = new User()
			
			next()
		
	]

# ## Implements hook `initialize`
exports.$initialize = -> (req, res, next) ->
	
	{models: User: User} = require 'server/jugglingdb'
	
	# Implement a local passport strategy.
	# `TODO`: Strategies should be dynamically defined, probably through a
	# hook.
	LocalStrategy = require('passport-local').Strategy
	passport.use new LocalStrategy (username, password, done) ->
		
		# Load a user and compare the hashed password.
		exports.loadByName(username).bind({}).then((@user)->
			return unless @user?
			
			crypto.hasher(
				plaintext: password
				salt: new Buffer @user.salt, 'hex'
			)
			
		).then((hashed) ->
			return unless @user?
			return unless @user.passwordHash is hashed.key.toString 'hex'
			
			@user
			
		).nodeify done
		
	passport.serializeUser (user, done) -> done null, user.id
	
	passport.deserializeUser (id, done) -> User.find(id).nodeify done
	
	next()
				
# ## Implements hook `models`
exports.$models = (schema) ->
	
	# Invoke the client hook implementation.
	clientModule.$models schema
	
	User = schema.models['User']
	
	# Extend the redaction function with server-specific information.
	User::redactFor = (user) ->
		
		Promise.cast(
			name: @name
			id: @id

		# Decrypt the e-mail if redacting for the same user.
		).bind({}).then((@redacted) ->
			return null unless @redacted.email?
			return @redacted.email unless user.id?
			return @redacted.email if user.id isnt @redacted.id
			
			crypto.decrypt @redacted.email
		
		).then((email) -> @redacted.email = email
		
		).then -> @redacted
		
# ## Implements hook `modelsAlter`
exports.$modelsAlter = clientModule.$modelsAlter

# ## Implements hook `socketAuthorizationMiddleware`
exports.$socketAuthorizationMiddleware = ->
	
	{models: User: User} = require 'server/jugglingdb'
	
	label: 'Load user using passport'
	middleware: [
	
		(req, res, next) ->
			
			# Augment our request object with certain methods from
			# `http.IncomingMessage`.
			for method in [
				'login', 'logIn'
				'logout', 'logOut'
				'isAuthenticated', 'isUnauthenticated'
			]
				req[method] = require('http').IncomingMessage.prototype[method]
			
			next()
			
		# Passport middleware.
		passport.initialize()
		passport.session()
		
		# Set the user into the request.
		(req, res, next) ->
			
			if req.user?
			
				req.user.logout = ->
					
					req.logout()
					req.user = new User()
					
					new Promise (resolve) ->
						
						# Alos log the client out, if we can.
						req.socket?.emit 'user.logout', null, ->
							resolve req.user
			
			else
			
				req.user = new User()
			
			next()
	
	]

# ## Implements hook `socketConnectionMiddleware`
exports.$socketConnectionMiddleware = ->
	
	{models: User: User} = require 'server/jugglingdb'
	
	label: 'Join channel for user'
	middleware: [
	
		(req, res, next) ->
			
			# Join a channel for the username.
			req.socket.join req.user.name if req.user.id?
			
			next()
	
	]

# ## loadByName
# 
# *Load a user by name.*
# 
# (string) `name` - The name of the user to load.
exports.loadByName = (name) ->
	
	{models: User: User} = require 'server/jugglingdb'
	
	User.findOne where: iname: name.toLowerCase()

exports[path] = require "packages/user/#{path}" for path in [
	'forgot', 'login', 'logout', 'register', 'reset'
]
