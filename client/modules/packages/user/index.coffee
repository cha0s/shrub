
Promise = require 'bluebird'

exports.$models = (schema) ->
	
	User = schema.define 'User',
		
		email:
			type: String
			index: true
		
		name:
			type: String
			default: 'Anonymous'
			length: 24
			index: true
			
		passwordHash:
			type: String
		
		resetPasswordToken:
			type: String
			length: 48
			index: true
		
		salt:
			type: String
			length: 128
			
	# Temporary... secure by default.
	User::hasPermission = (perm) -> false
	User::isAccessibleBy = (user) -> false
	
	User::redactFor = (user) ->
		
		redacted =
			name: @name
			id: @id
			email: @email
		
		Promise.resolve redacted

augmentModel = (User, Model, name) ->
	
	validateUser = (user) ->
		
		new Promise (resolve, reject) ->
		
			return resolve() if user instanceof User
				
			error = new Error "Invalid user."
			error.code = 500
			reject error
	
	checkPermission = (user, perm) ->
	
		new Promise (resolve, reject) ->

			return resolve() if user.hasPermission perm
				
			error = new Error "Access denied."
			error.code = 403
			reject error
			
	Model.authenticatedAll = (user, params) ->
		
		validateUser(user).then(->

			checkPermission user, "schema:#{name}:all"
		
		).then(->
			
			Model.all params
		
		).then((models) ->
			
			models.filter (model) -> model.isAccessibleBy user
		
		).then((models) ->
			
			Promise.all models.map (model) -> model.redactFor user
		
		).then (models) ->
			
			return models if models.length > 0
			
			error = new Error "Collection not found."
			error.code = 404
			Promise.reject error
	
	Model.authenticatedCount = (user) ->
		
		validateUser(user).then(->
			
			checkPermission user, "schema:#{name}:count"
		
		).then -> Model.count()
		
	Model.authenticatedCreate = (user, properties) ->

		validateUser(user).then(->
			
			checkPermission user, "schema:#{name}:create"
		
		).then -> Model.create properties

	Model.authenticatedDestroy = (user, id) ->
	
		validateUser(user).then(->
			
			checkPermission user, "schema:#{name}:create"
		
		).then(->
			
			Model.authenticatedFind user, id
		
		).then (model) ->
		
			return model.destroy() if model.isDeletableBy user
				
			if model.isAccessibleBy user
				error = new Error "Access denied."
				error.code = 403
			else
				error = new Error "Resource not found."
				error.code = 404
			
			Promise.reject error
	
	Model.authenticatedDestroyAll = (user) ->
	
		validateUser(user).then(->
			
			checkPermission "schema:#{name}:destroyAll"
		
		).then ->
			
			Model.destroyAll()
		
	Model.authenticatedFind = (user, id) ->

		validateUser(user).then(->
			
			Model.find id
	
		).then (model) ->
			
			if model? and model.isAccessibleBy user
				return model.redactFor user
			
			error = new Error "Resource not found."
			error.code = 404
			Promise.reject error
	
	Model.authenticatedUpdate = (user, id, properties) ->

		validateUser(user).then(->
			
			Model.authenticatedFind user, id
		
		).then (model) ->
			
			if model.isEditableBy user
				return model.updateAttributes properties
				
			if model.isAccessibleBy user
				error = new Error "Access denied."
				error.code = 403
			else
				error = new Error "Resource not found."
				error.code = 404
			
			Promise.reject error
		
	Model::isAccessibleBy ?= (user) -> true
	Model::isEditableBy ?= (user) -> false
	Model::isDeletableBy ?= (user) -> false
	Model::redactFor ?= (user) -> Promise.resolve this

exports.$modelsAlter = (models) ->
	
	augmentModel models.User, Model, name for name, Model of models
		
exports.$service = -> [
	'$q', 'config', 'rpc', 'schema'
	($q, config, rpc, schema) ->
		
		service = {}
		
		user = new schema.models.User
		
		service.isLoggedIn = -> service.instance().id? 
			
		service.login = (method, username, password) ->
			
			rpc.call(
				'user.login'
				method: method
				username: username
				password: password
			).then(
				(O) ->
					user.fromObject O
					user
			)

		service.logout = ->
			
			rpc.call(
				'user.logout'
			).then(
				->
					user.fromObject (new schema.models.User).toObject()
					user
			)
		
		isLoaded = false
		service.instance = ->
			
			unless isLoaded
				isLoaded = true
				user.fromObject config.get 'user'
			
			user
		
		service
		
]

exports.$serviceMock = -> [
	'$delegate', 'socket'
	($delegate, socket) ->
		
		$delegate.fakeLogin = (username, password = 'password', id = 1) ->
	
			socket.catchEmit 'rpc://user.login', (data, fn) ->
				fn result: id: id, name: username
				
			$delegate.login 'local', username, password
			
		$delegate
	
]

exports[path] = require "./#{path}" for path in [
	'forgot', 'login', 'logout', 'register', 'reset'
]
