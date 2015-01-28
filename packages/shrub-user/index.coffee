
# # User
#
# User operations.

passport = require 'passport'
Promise = require 'bluebird'

crypto = require 'server/crypto'
orm = require 'shrub-orm'

clientModule = require './client'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `config`
	registrar.registerHook 'config', (req) ->

		# Send a redacted version of the request user.
		req.user.redactFor req.user if req.user?

	# ## Implements hook `endpointFinished`
	registrar.registerHook 'endpointFinished', (routeReq, result, req) ->
		return unless routeReq.user.id?

		# Touch and save the session after every RPC call finishes.
		deferred = Promise.defer()
		routeReq.user.touch().save deferred.callback

		# Propagate changes back up to the original request.
		deferred.promise.then -> req.user = routeReq.user

	# ## Implements hook `fingerprint`
	registrar.registerHook 'fingerprint', (req) ->

		# User (ID).
		user: if req?.user?.id? then req.user.id

	# ## Implements hook `httpMiddleware`
	registrar.registerHook 'httpMiddleware', (http) ->

		label: 'Load user using passport'
		middleware: [

			# Passport middleware.
			passport.initialize()
			passport.session()

			# Set the user into the request.
			(req, res, next) ->

				User = orm.collection 'shrub-user'
				req.user = User.instantiate() unless req.user?

				next()

		]

	# ## Implements hook `collections`
	registrar.registerHook 'collections', ->

		# Invoke the client hook implementation.
		collections = clientModule.collections()

		{'shrub-user': User} = collections

		(User.redactors = []).push (redacted) ->

			delete redacted.iname
			delete redacted.plaintext if redacted.plaintext?
			delete redacted.salt
			delete redacted.passwordHash
			delete redacted.resetPasswordToken
			return unless redacted.email?

			# Different redacted means full email redaction.
			if @id isnt redacted.id
				delete redacted.email
				return

			# Decrypt the e-mail if redacting for the same user.
			crypto.decrypt(redacted.email).then (email) ->
				redacted.email = email

		collections

	# ## Implements hook `collectionsAlter`
	registrar.registerHook 'collectionsAlter', (collections) ->
		clientModule.collectionsAlter collections

		for identity, collection of collections
			do (identity, collection) ->

				collection.redactors ?= []
				collection.attributes.redactFor = (user) ->
					redacted = @toJSON()

					Promise.all(
						for redactor in collection.redactors
							redactor.call user, redacted
					).then -> redacted

	# ## Implements hook `packageSettings`
	registrar.registerHook 'packageSettings', ->

		beforeLoginMiddleware: []

		afterLoginMiddleware: []

		beforeLogoutMiddleware: [
			'shrub-user'
		]

		afterLogoutMiddleware: [
			'shrub-user'
		]

	# ## Implements hook `socketAuthorizationMiddleware`
	registrar.registerHook 'socketAuthorizationMiddleware', ->

		label: 'Load user using passport'
		middleware: [

			# Passport middleware.
			passport.initialize()
			passport.session()

			# Set the user into the request.
			(req, res, next) ->

				User = orm.collection 'shrub-user'
				req.user = User.instantiate() unless req.user?

				next()

		]

	# ## Implements hook `socketConnectionMiddleware`
	registrar.registerHook 'socketConnectionMiddleware', ->

		label: 'Join channel for user'
		middleware: [

			(req, res, next) ->

				# Join a channel for the username.
				return req.socket.join req.user.name, next if req.user.id?

				next()

		]

	# ## Implements hook `userBeforeLogoutMiddleware`
	registrar.registerHook 'userBeforeLogoutMiddleware', ->

		label: 'Tell client to log out, and leave the user channel'
		middleware: [

			({req, user}, res, next) ->

				if req.socket?

					# Tell client to log out.
					req.socket.emit 'shrub.user.logout'

					# Leave the user channel.
					req.socket.leave req.user.name if req.user.id?

				next()

		]

	# ## Implements hook `userAfterLogoutMiddleware`
	registrar.registerHook 'userAfterLogoutMiddleware', ->

		label: 'Instantiate anonymous user'
		middleware: [

			({req, user}, res, next) ->

				User = orm.collection 'shrub-user'
				req.user = User.instantiate()

				next()

		]

	registrar.recur [
		'forgot', 'login', 'logout', 'register', 'reset'
	]

# ## loadByName
#
# *Load a user by name.*
#
# (string) `name` - The name of the user to load.
exports.loadByName = (name) ->

	User = orm.collection 'shrub-user'
	User.findOne iname: name.toLowerCase()
