
i8n = require 'inflection'
passport = require 'passport'
Promise = require 'bluebird'

crypto = require 'server/crypto'
errors = require 'errors'
middleware = require 'middleware'
schema = require 'schema'

{defaultLogger} = require 'logging'
{threshold} = require 'limits'

clientModule = require 'client/modules/packages/user/login'
userPackage = require 'packages/user'

# ## Implements hook `endpoint`
exports.$endpoint = ->
	
	limiter:
		message: "You are logging in too much."
		threshold: threshold(3).every(30).seconds()

	receiver: (req, fn) ->
		
		passport = req._passport.instance
		
		loginPromise = switch req.body.method
			
			when 'local'
				
				res = {}
				
				deferred = Promise.defer()
				passport.authenticate('local', deferred.callback) req, res, fn
				
				# Log the user in (if it exists), and redact it for the
				# response.
				deferred.promise.bind({}).spread((@user, info) ->
					throw errors.instantiate 'login' unless @user
					
					req.login @user
					
				).then ->
					
					# Join a channel for the username.
					req.socket.join @user.name
					
					@user.redactFor @user
				
# } Using nodeify here crashes the app. It may be a bluebird bug.
		
		loginPromise.then((user) -> fn null, user
		).catch fn

# ## Implements hook `initialize`
exports.$initialize = ->
	
	{User} = schema.models
	
	# Implement a local passport strategy.
	# `TODO`: Strategies should be dynamically defined, probably through a
	# hook.
	LocalStrategy = require('passport-local').Strategy
	passport.use new LocalStrategy (username, password, done) ->
		
		# Load a user and compare the hashed password.
		userPackage.loadByName(username).bind({}).then((@user)->
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
	
	monkeyPatchLogin()
	
# Monkey patch http.IncomingMessage.prototype.login to run our middleware,
# and return a promise.
monkeyPatchLogin = ->
		
	{IncomingMessage} = require 'http'
	
	req = IncomingMessage.prototype
	
	# Invoke hook `userBeforeLoginMiddleware`.
	# Invoked before a user logs in.
	userBeforeLoginMiddleware = middleware.fromShortName 'user before login'

	# Invoke hook `userAfterLoginMiddleware`.
	# Invoked after a user logs in.
	userAfterLoginMiddleware = middleware.fromShortName 'user after login'
	
	login = req.login
	req.login = req.logIn = (user, fn) ->
		
		new Promise (resolve, reject) =>
		
			loginReq = req: this, user: user
			
			userBeforeLoginMiddleware.dispatch loginReq, null, (error) =>
				return reject error if error?
				
				login.call this, loginReq.user, (error) ->
					return reject error if error?
					
					userAfterLoginMiddleware.dispatch loginReq, null, (error) ->
						return reject error if error?
						
						resolve()

# ## Implements hook `transmittableError`
exports.$transmittableError = clientModule.$transmittableError
