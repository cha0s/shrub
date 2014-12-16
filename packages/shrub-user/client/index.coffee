
# # User
# 
# User operations, model, etc.

Promise = require 'bluebird'

config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `collections`
	registrar.registerHook 'collections', exports.collections
		
	# ## Implements hook `collectionsAlter`
	registrar.registerHook 'collectionsAlter', exports.collectionsAlter
			
	# ## Implements hook `service`		
	registrar.registerHook 'service', -> [
		'shrub-orm', 'shrub-rpc', 'shrub-socket'
		(orm, rpc, socket) ->
			
			service = {}
			
			_instance = {}
			
			_instance = name: 'Loading...'
			
			orm.collection('shrub-user').then (User) ->
				_instance = User.instantiate(
					config.get 'packageConfig:shrub-user'
				)
			
			# Log a user out if we get a socket call.
			logout = ->
			
				orm.collection('shrub-user').then (User) ->
					blank = User.instantiate()
					delete _instance[k] for k of _instance
					delete _instance[k] = v for k, v of blank
				
				return
			
			socket.on 'shrub.user.logout', logout
			
			# ## user.isLoggedIn
			# 
			# *Whether the current application user is logged in.*
			service.isLoggedIn = -> service.instance().id? 
				
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
				
				).then (O) -> orm.collection('shrub-user').then (User) ->
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
			
			service
			
	]
	
	# ## Implements hook `serviceMock`
	registrar.registerHook 'serviceMock', -> [
		'$delegate', 'shrub-socket'
		($delegate, socket) ->
			
			# ## user.fakeLogin
			# 
			# *Mock a login process.*
			# 
			# `TODO`: This will change when login method generalization happens.
			$delegate.fakeLogin = (username, password = 'password', id = 1) ->
				socket.catchEmit 'rpc://shrub.user.login', (data, fn) ->
					fn result: id: id, name: username
					
				$delegate.login 'local', username, password
				
			$delegate
		
	]
	
	registrar.recur [
		'forgot', 'login', 'logout', 'register', 'reset'
	]
	
exports.collections = ->

	return 'shrub-user':
	
		attributes:
	
			# Last time this user was accessed.
			lastAccessed:
				type: 'datetime'
				defaultsTo: -> new Date()
			
			# Email address.
			email:
				type: 'string'
				index: true
			
			# Case-insensitivized name.
			iname:
				type: 'string'
				size: 24
				index: true
				
			# Name.
			name:
				type: 'string'
				defaultsTo: 'Anonymous'
				size: 24
				maxLength: 24
				
			# Hash of the plaintext password.
			passwordHash:
				type: 'string'
			
			# A token which can be used to reset the user's password (once).
			resetPasswordToken:
				type: 'string'
				size: 48
				index: true
			
			# A 512-bit salt used to cryptographically hash the user's password.
			salt:
				type: 'string'
				size: 128

			# Update a user's last accessed time. Return the user for chaining.
			touch: ->
				@lastAccessed = (new Date()).toISOString()
				this
					
			# Temporary... secure by default.
			# `TODO`: Access control structure.
			hasPermission: (perm) -> false
			isAccessibleBy: (user) -> false
		
exports.collectionsAlter = (collections) ->

	# `TODO`: This is broken since ORM change
	{'shrub-user': User} = collections
	
	# Implement all the built-in collection methods as authenticated versions,
	# which take a user.
	for identity, collection of collections
		do (identity, collection) ->
	
			validateUser = (user) ->
				
				new Promise (resolve, reject) ->
				
					# `TODO`: See if we can do this without using the internal
					# _model property.
					return resolve()# if user instanceof User._model
						
					error = new Error "Invalid user."
					error.code = 500
					reject error
			
			checkPermission = (user, perm) ->
			
				return if user.hasPermission perm
					
				error = new Error "Forbidden."
				error.code = 403
				throw error
					
			collection.authenticatedAll = (user, params) ->
				
				validateUser(user).then(->
					checkPermission user, "shrub-orm:#{name}:all"
				
				).then(->
					orm.collection(identity).all params
				
				).then (models) ->
					return models if models.length > 0
					
					error = new Error "Collection not found."
					error.code = 404
					Promise.reject error
			
			collection.authenticatedCount = (user) ->
				
				validateUser(user).then(->
					checkPermission user, "shrub-orm:#{name}:count"
				
				).then -> orm.collection(identity).count()
				
			collection.authenticatedCreate = (user, attributes) ->
		
				validateUser(user).then(->
					checkPermission user, "shrub-orm:#{name}:create"
				
				).then -> orm.collection(identity).create attributes
		
			collection.authenticatedDestroy = (user, id) ->
			
				validateUser(user).then(->
					checkPermission user, "shrub-orm:#{name}:create"
				
				).then(->
					collection.authenticatedFind user, id
				
				).then (model) ->
					return model.destroy() if model.isDeletableBy user
						
					if model.isAccessibleBy user
						error = new Error "Access denied."
						error.code = 403
					else
						error = new Error "Resource not found."
						error.code = 404
					
					Promise.reject error
			
			collection.authenticatedDestroyAll = (user) ->
			
				validateUser(user).then(->
					checkPermission "shrub-orm:#{name}:destroyAll"
				
				).then -> orm.collection(identity).destroyAll()
				
			collection.authenticatedFind = (user, id) ->
		
				validateUser(user).then(->
					orm.collection(identity).find id
			
				).then (model) ->
					return model if model? and model.isAccessibleBy user
					
					error = new Error "Resource not found."
					error.code = 404
					Promise.reject error
			
			collection.authenticatedUpdate = (user, id, attributes) ->
		
				validateUser(user).then(->
					collection.authenticatedFind user, id
				
				).then (model) ->
					if model.isEditableBy user
						for k, v of attributes
							model[k] = v
						model.id = id
						return model.save()
						
					if model.isAccessibleBy user
						error = new Error "Access denied."
						error.code = 403
					else
						error = new Error "Resource not found."
						error.code = 404
					
					Promise.reject error
				
			collection.attributes.isAccessibleBy ?= (user) -> false
			collection.attributes.isEditableBy ?= (user) -> false
			collection.attributes.isDeletableBy ?= (user) -> false
			
	return
