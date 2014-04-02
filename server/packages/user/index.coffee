
# # User
# 
# User oprations. 

passport = require 'passport'
Promise = require 'bluebird'

crypto = require 'server/crypto'
schema = require 'schema'

clientModule = require 'client/modules/packages/user'

# ## Implements hook `config`
exports.$config = (req) ->

	# Send a redacted version of the request user.
	req.user.redactFor(req.user).then (redacted) -> user: redacted

# ## Implements hook `endpointFinished`
exports.$endpointFinished = (routeReq, result, req) ->
	return unless routeReq.user.id?
	
	# Propagate changes back up to the original request.
	req.user = routeReq.user

# ## Implements hook `fingerprint`
exports.$fingerprint = (req) ->

	# User (ID).
	user: if req?.user?.id? then req.user.id

# ## Implements hook `httpMiddleware`
exports.$httpMiddleware = (http) ->
	
	{User} = schema.models
	
	label: 'Load user using passport'
	middleware: [
		
		# Passport middleware.
		passport.initialize()
		passport.session()
		
		# Set the user into the request.
		(req, res, next) ->
			
			req.user = new User() unless req.user?
			
			next()
		
	]

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

# ## Implements hook `packageSettings`
exports.$packageSettings = ->
	
	beforeLoginMiddleware: []
	
	afterLoginMiddleware: []
	
	beforeLogoutMiddleware: [
		'user'
	]

	afterLogoutMiddleware: [
		'user'
	]

# ## Implements hook `socketAuthorizationMiddleware`
exports.$socketAuthorizationMiddleware = ->
	
	{User} = schema.models
	
	label: 'Load user using passport'
	middleware: [
	
		# Passport middleware.
		passport.initialize()
		passport.session()
		
		# Set the user into the request.
		(req, res, next) ->
			
			req.user = new User() unless req.user?
			
			next()
	
	]

# ## Implements hook `socketConnectionMiddleware`
exports.$socketConnectionMiddleware = ->
	
	{User} = schema.models
	
	label: 'Join channel for user'
	middleware: [
	
		(req, res, next) ->
			
			# Join a channel for the username.
			req.socket.join req.user.name if req.user.id?
			
			next()
	
	]

# ## Implements hook `userBeforeLogoutMiddleware`
exports.$userBeforeLogoutMiddleware = ->
	
	label: 'Tell client to log out, and leave the user channel'
	middleware: [
	
		({req, user}, res, next) ->
			
			if req.socket?
				
				# Tell client to log out.
				req.socket.emit 'user.logout'
				
				# Leave the user channel.
				req.socket.leave req.user.name
			
			next()
			
	]

# ## Implements hook `userAfterLogoutMiddleware`
exports.$userAfterLogoutMiddleware = ->
	
	{User} = schema.models
			
	label: 'Instantiate anonymous user'
	middleware: [
	
		({req, user}, res, next) ->
			
			req.user = new User()
			
			next()
			
	]

# ## loadByName
# 
# *Load a user by name.*
# 
# (string) `name` - The name of the user to load.
exports.loadByName = (name) ->
	
	{User} = schema.models
	
	User.findOne where: iname: name.toLowerCase()

exports[path] = require "packages/user/#{path}" for path in [
	'forgot', 'login', 'logout', 'register', 'reset'
]
