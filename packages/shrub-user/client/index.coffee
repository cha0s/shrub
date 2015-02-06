
# # User
#
# User operations, model, etc.

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `collections`
	registrar.registerHook 'collections', exports.collections

	# ## Implements hook `collectionsAlter`
	registrar.registerHook 'collectionsAlter', exports.collectionsAlter

	# ## Implements hook `service`
	registrar.registerHook 'service', -> [
		'shrub-orm', 'shrub-rpc', 'shrub-socket'
		(orm, rpc, socket) ->

			config = require 'config'

			User = orm.collection 'shrub-user'

			service = {}

			_instance = {}
			_instance[k] = v for k, v of User.instantiate(
				config.get 'packageConfig:shrub-user'
			)

			# Log a user out if we get a socket call.
			logout = ->

				blank = User.instantiate()
				delete _instance[k] for k of _instance
				_instance[k] = v for k, v of blank

				return

			socket.on 'shrub.user.logout', logout

			# ## user.isLoggedIn
			#
			# *Whether the current application user is logged in.*
			service.isLoggedIn = -> _instance.id?

			# ## user.login
			#
			# *Log in with method and args.*
			#
			# `TODO`: username and password are tightly coupled to local
			# strategy. Change that.
			service.login = (method, username, password) ->

				rpc.call(
					'shrub.user.login'
					method: method
					username: username
					password: password

				).then (O) ->
					_instance[k] = v for k, v of O
					return

			# ## user.logout
			#
			# *Log out.*
			service.logout = ->

				rpc.call(
					'shrub.user.logout'

				).then logout

			# ## user.instance
			#
			# *Retrieve the user instance.*
			service.instance = -> _instance

			if config.get 'packageConfig:shrub-core:testMode'

				# ## user.fakeLogin
				#
				# *Mock a login process.*
				#
				# `TODO`: This will change when login method generalization
				# happens.
				service.fakeLogin = (username, password, id) ->
					password ?= 'password'
					id ?= 1

					socket.catchEmit 'rpc://shrub.user.login', (data, fn) ->
						fn result: id: id, name: username

					service.login 'local', username, password

			service

	]

	registrar.recur [
		'email', 'forgot', 'login', 'logout', 'register', 'reset'
	]

exports.collections = ->

	Group =

		attributes:

			name:
				type: 'string'
				size: 24
				maxLength: 24

			permissions:
				collection: 'shrub-group-permission'
				via: 'group'

	GroupPermission =

		attributes:

			permission: 'string'

			group: model: 'shrub-group'

	User =

		attributes:

			# Last time this user was accessed.
			lastAccessed:
				type: 'datetime'
				defaultsTo: -> new Date()

			# Email address.
			email:
				type: 'string'
				index: true

			# Name.
			name:
				type: 'string'
				defaultsTo: 'Anonymous'
				size: 24
				maxLength: 24

			# Groups this user belongs to.
			groups:
				collection: 'shrub-user-group'
				via: 'user'

			# Groups this user belongs to.
			permissions:
				collection: 'shrub-user-permission'
				via: 'user'

			# Check whether a user has a permission.
			hasPermission: (permission) ->

				# Superuser?
				return true if @id is 1

				# Check group permissions.
				for {permissions} in @groups
					return true if ~permissions.indexOf permission

				# Check inline permissions.
				return ~@permissions.indexOf permission

	UserGroup =

		attributes:

			group: model: 'shrub-group'

			user: model: 'shrub-user'

	UserPermission =

		attributes:

			permission: 'string'

			user: model: 'shrub-user'

	'shrub-group': Group
	'shrub-group-permission': GroupPermission
	'shrub-user': User
	'shrub-user-group': UserGroup
	'shrub-user-permission': UserPermission

exports.collectionsAlter = (collections) ->

	Promise = require 'bluebird'

	# `TODO`: This is broken since ORM change
	{'shrub-user': User} = collections

	# Implement all the built-in collection methods as authenticated versions,
	# which take a user.
	for identity, collection of collections
		do (identity, collection) ->

			# validateUser = (user) ->

			# 	new Promise (resolve, reject) ->

			# 		# `TODO`: See if we can do this without using the internal
			# 		# _model property.
			# 		return resolve()# if user instanceof User._model

			# 		error = new Error "Invalid user."
			# 		error.code = 500
			# 		reject error

			# checkPermission = (user, perm) ->

			# 	return if user.hasPermission perm

			# 	error = new Error "Forbidden."
			# 	error.code = 403
			# 	throw error

			# # Secure by default.
			# collection.attributes.isAccessibleBy ?= (user) -> false

			# collection.authenticatedAll = (user, params) ->

			# 	validateUser(user).then(->
			# 		checkPermission user, "shrub-orm:#{name}:all"

			# 	).then(->
			# 		orm.collection(identity).all params

			# 	).then (models) ->
			# 		return models if models.length > 0

			# 		error = new Error "Collection not found."
			# 		error.code = 404
			# 		Promise.reject error

			# collection.authenticatedCount = (user) ->

			# 	validateUser(user).then(->
			# 		checkPermission user, "shrub-orm:#{name}:count"

			# 	).then -> orm.collection(identity).count()

			# collection.authenticatedCreate = (user, attributes) ->

			# 	validateUser(user).then(->
			# 		checkPermission user, "shrub-orm:#{name}:create"

			# 	).then -> orm.collection(identity).create attributes

			# collection.authenticatedDestroy = (user, id) ->

			# 	validateUser(user).then(->
			# 		checkPermission user, "shrub-orm:#{name}:create"

			# 	).then(->
			# 		collection.authenticatedFind user, id

			# 	).then (model) ->
			# 		return model.destroy() if model.isDeletableBy user

			# 		if model.isAccessibleBy user
			# 			error = new Error "Access denied."
			# 			error.code = 403
			# 		else
			# 			error = new Error "Resource not found."
			# 			error.code = 404

			# 		Promise.reject error

			# collection.authenticatedDestroyAll = (user) ->

			# 	validateUser(user).then(->
			# 		checkPermission "shrub-orm:#{name}:destroyAll"

			# 	).then -> orm.collection(identity).destroyAll()

			# collection.authenticatedFind = (user, id) ->

			# 	validateUser(user).then(->
			# 		orm.collection(identity).find id

			# 	).then (model) ->
			# 		return model if model? and model.isAccessibleBy user

			# 		error = new Error "Resource not found."
			# 		error.code = 404
			# 		Promise.reject error

			# collection.authenticatedUpdate = (user, id, attributes) ->

			# 	validateUser(user).then(->
			# 		collection.authenticatedFind user, id

			# 	).then (model) ->
			# 		if model.isEditableBy user
			# 			for k, v of attributes
			# 				model[k] = v
			# 			model.id = id
			# 			return model.save()

			# 		if model.isAccessibleBy user
			# 			error = new Error "Access denied."
			# 			error.code = 403
			# 		else
			# 			error = new Error "Resource not found."
			# 			error.code = 404

			# 		Promise.reject error

			collection.attributes.isAccessibleBy ?= (user) -> false
			collection.attributes.isEditableBy ?= (user) -> false
			collection.attributes.isDeletableBy ?= (user) -> false

	return
