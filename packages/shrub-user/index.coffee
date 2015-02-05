
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

	instantiateAnonymous = ->

		@user = orm.collection('shrub-user').instantiate()

		# Add to anonymous group.
		@user.groups = [
			orm.collection('shrub-user-group').instantiate group: 3
		]

		@user.populateAll()

	# ## Implements hook `httpMiddleware`
	registrar.registerHook 'httpMiddleware', ->

		label: 'Load user using passport'
		middleware: [

			(req, res, next) ->

				req.instantiateAnonymous = instantiateAnonymous
				next()

			# Passport middleware.
			passport.initialize()
			passport.session()

			# Set the user into the request.
			(req, res, next) ->
				promise = if req.user?
					Promise.resolve()
				else
					req.instantiateAnonymous()

				promise.then(-> next()).catch next

		]

	# ## Implements hook `collections`
	registrar.registerHook 'collections', ->

		# Invoke the client hook implementation.
		collections = clientModule.collections()

		{
			'shrub-group': Group
			'shrub-user': User
			'shrub-user-group': UserGroup
		} = collections

		# Case-insensitivized name.
		Group.attributes.iname =
			type: 'string'
			size: 24
			index: true

		# Case-insensitivized name.
		User.attributes.iname =
			type: 'string'
			size: 24
			index: true

		# Hash of the plaintext password.
		User.attributes.passwordHash =
			type: 'string'

		# A token which can be used to reset the user's password (once).
		User.attributes.resetPasswordToken =
			type: 'string'
			size: 48
			index: true

		# A 512-bit salt used to cryptographically hash the user's password.
		User.attributes.salt =
			type: 'string'
			size: 128

		# Update a user's last accessed time. Return the user for chaining.
		User.attributes.touch = ->
			@lastAccessed = (new Date()).toISOString()
			this

		User.attributes.populateAll = ->
			self = this

			Group_ = orm.collection 'shrub-group'

			@_groups = (group.toJSON() for group in @groups)

			promises = for {group}, index in @groups

				do (group, index) ->

					Group_.findOne(id: group).populateAll().then (group_) ->

						self.groups[index] = group_

			Promise.all(promises).then -> self

		User.attributes.depopulateAll = ->

			@groups = @_groups
			delete @_groups

		User.attributes.toJSON = ->
			O = @toObject()
			O.groups = (group for group in @groups)
			O

		User.redactors = [(redactFor) ->
			self = this

			delete self.iname
			delete self.plaintext if self.plaintext?
			delete self.salt
			delete self.passwordHash
			delete self.resetPasswordToken

			delete self._groups if self._groups?

			for group in self.groups

				for permission in group.permissions

					delete permission.group
					delete permission.id
					delete permission.toJSON

				delete group.iname
				delete group.id

			Promise.resolve().then ->
				return unless self.email?

				# Different redacted means full email redaction.
				if redactFor.id isnt self.id
					delete self.email
					return

				# Decrypt the e-mail if redacting for the same user.
				crypto.decrypt(self.email).then (email) ->
					self.email = email

		]

		UserGroup.attributes.populateAll = ->
			self = this

			Group_ = orm.collection 'shrub-group'
			Group_.findOne(id: self.group).populateAll().then (group_) ->
				self.group = group_

				return self

		UserGroup.attributes.depopulateAll = ->
			@group = @group.id

			return this

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
							redactor.call redacted, user
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

			(req, res, next) ->

				req.instantiateAnonymous = instantiateAnonymous
				next()

			# Passport middleware.
			passport.initialize()
			passport.session()

			# Set the user into the request.
			(req, res, next) ->
				promise = if req.user?
					Promise.resolve()
				else
					req.instantiateAnonymous()

				promise.then(-> next()).catch next

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
	User.findOne(iname: name.toLowerCase()).populateAll()
