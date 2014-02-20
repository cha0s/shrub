
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
			length: 128
			index: true
		
		salt:
			type: String
			length: 128
			
	# Temporary... secure by default.
	User::hasPermission = (perm) -> false
	User::isAccessibleBy = (user) -> false
	
	User::redactFor = (user, fn) ->
		
		@passwordHash = null
		@resetPasswordToken = null
		@salt = null
		
		fn null, this

augmentModel = (User, Model, name) ->
	
	validateUser = (next) -> (user) ->
		return next.apply null, arguments if user instanceof User
		
		error = new Error "Invalid user."
		error.code = 500
		fn error
	
	checkPermission = (user, perm, fn, next) ->
		return next() if user.hasPermission perm
		
		error = new Error "Access denied."
		error.code = 403
		fn error
		
	interceptError = (fn, next) -> (error, result) ->
		return fn error if error?
		
		next result

	Model.authenticatedAll = validateUser (user, params, fn) ->
		unless fn?
			fn = params
			params = {}
		
		checkPermission user, "schema:#{name}:all", fn, ->
			Model.all params, interceptError fn, (models) ->
				models = models.filter (model) -> model.isAccessibleBy user
				
				if models.length
					redactedModelCount = 0
					redactedModels = []
					for model, i in models
						do (model, i) ->
							model.redactFor user, interceptError fn, (redactedModel) ->
								redactedModels[i] = redactedModel
								redactedModelCount += 1
								if redactedModelCount is models.length
									fn null, redactedModels
				else
					error = new Error "Collection not found."
					error.code = 404
					fn error
	
	Model.authenticatedCount = validateUser (user, fn) ->
		checkPermission user, "schema:#{name}:count", fn, ->
			Model.count interceptError fn, (count) ->
				fn null, count
	
	Model.authenticatedCreate = validateUser (user, properties, fn) ->
		checkPermission user, "schema:#{name}:create", fn, ->
			Model.create properties, interceptError fn, (model) ->
				fn null, model

	Model.authenticatedDestroy = validateUser (user, id, fn) ->				
		Model.authenticatedFind user, id, interceptError fn, (model) ->
			if model.isDeletableBy user
				schema.adapter.destroy name, id, interceptError fn, (result) ->
					fn()
			else
				if model.isAccessibleBy user
					error = new Error "Access denied."
					error.code = 403
				else
					error = new Error "Resource not found."
					error.code = 404
				fn error

	Model.authenticatedDestroyAll = validateUser (user, fn) ->
		checkPermission user, "schema:#{name}:destroyAll", fn, ->
			Model.destroyAll interceptError fn, ->
				fn()
	
	Model.authenticatedFind = validateUser (user, id, fn) ->
		Model.find id, interceptError fn, (model) ->
			if model? and model.isAccessibleBy user
				model.redactFor user, interceptError fn, (redactedModel) ->
					fn null, redactedModel
			else
				error = new Error "Resource not found."
				error.code = 404
				fn error

	Model.authenticatedUpdate = validateUser (user, id, properties, fn) ->
		Model.authenticatedFind user, id, interceptError fn, (model) ->
			if model.isEditableBy user
				model.updateAttributes properties, interceptError fn, (model) ->
					fn()
			else
				if model.isAccessibleBy user
					error = new Error "Access denied."
					error.code = 403
				else
					error = new Error "Resource not found."
					error.code = 404
				fn error
	
	Model::isAccessibleBy ?= (user) -> true
	Model::isEditableBy ?= (user) -> false
	Model::isDeletableBy ?= (user) -> false
	Model::redactFor ?= (user, fn) -> fn null, this

exports.$modelsAlter = (models) ->
	
	augmentModel models.User, Model, name for name, Model of models
		
exports.$service = [
	'$q', 'config', 'core', 'rpc', 'schema'
	($q, config, core, rpc, schema) ->
		
		service = {}
		
		user = new schema.models.User
		
		service.isLoggedIn = (fn) -> service.instance().id? 
			
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
		
		promiseifyModelMethods = (Model, methodName) =>
			method = Model[methodName]
			Model[methodName] = core.promiseify Model, (args...) ->
				method.apply Model, [service.instance()].concat args
			
		promiseifyModelMethods methodName for methodName in [
			'all', 'authenticatedAll'
			'count', 'authenticatedCount'
			'create', 'authenticatedCreate'
			'destroy', 'authenticatedDestroy'
			'destroyAll', 'authenticatedDestroyAll'
			'find', 'authenticatedFind'
			'update', 'authenticatedUpdate'
		] for name, Model of schema.models
		
		service
		
]

exports[path] = require "packages/user/#{path}" for path in [
	'forgot', 'login', 'logout', 'register', 'reset'
]
