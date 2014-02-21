
Q = require 'bluebird'

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
	
	User::redactFor = (user) ->
		
		@passwordHash = null
		@resetPasswordToken = null
		@salt = null
		
		Q.resolve this

augmentModel = (User, Model, name) ->
	
	validateUser = (user) ->
		
		deferred = Q.defer()
			
		if user instanceof User
			
			deferred.resolve()
		
		else
		
			error = new Error "Invalid user."
			error.code = 500
			deferred.reject error
		
		deferred.promise
	
	checkPermission = (user, perm) ->
	
		deferred = Q.defer()
			
		if user.hasPermission perm
			
			deferred.resolve()
			
		else
		
			error = new Error "Access denied."
			error.code = 403
			deferred.reject error
		
		deferred.promise

	Model.authenticatedAll = (user, params) ->
		
		(validateUser user).then(->

			checkPermission user, "schema:#{name}:all"
		
		).then(->
			
			Model.all params
		
		).then((models) ->
			
			models.filter (model) -> model.isAccessibleBy user
		
		).then((models) ->
			
			Q.all models.map (model) -> model.redactFor user
		
		).then (models) ->
			
			if models.length is 0
			
				error = new Error "Collection not found."
				error.code = 404
				
				Q.reject error
			
			else
				
				models
	
	Model.authenticatedCount = (user) ->
		
		(validateUser user).then(->
			
			checkPermission user, "schema:#{name}:count"
		
		).then -> Model.count()
		
	Model.authenticatedCreate = (user, properties) ->

		(validateUser user).then(->
			
			checkPermission user, "schema:#{name}:create"
		
		).then -> Model.create properties

	Model.authenticatedDestroy = (user, id) ->
	
		(validateUser user).then(->
			
			checkPermission user, "schema:#{name}:create"
		
		).then(->
			
			Model.authenticatedFind user, id
		
		).then (model) ->
		
			if model.isDeletableBy user
				
				model.destroy()
				
			else
				
				if model.isAccessibleBy user
					error = new Error "Access denied."
					error.code = 403
				else
					error = new Error "Resource not found."
					error.code = 404
				
				Q.reject error
	
	Model.authenticatedDestroyAll = (user) ->
	
		(validateUser user).then(->
			
			checkPermission "schema:#{name}:destroyAll"
		
		).then ->
			
			Model.destroyAll()
		
	Model.authenticatedFind = (user, id) ->

		(validateUser user).then(->
			
			Model.find id
	
		).then (model) ->
			
			if model? and model.isAccessibleBy user
				
				model.redactFor user
			
			else
				
				error = new Error "Resource not found."
				error.code = 404
				Q.reject error
	
	Model.authenticatedUpdate = (user, id, properties) ->

		(validateUser user).then(->
			
			Model.authenticatedFind user, id
		
		).then (model) ->
			
			if model.isEditableBy user
				
				model.updateAttributes properties
				
			else
				
				if model.isAccessibleBy user
					error = new Error "Access denied."
					error.code = 403
				else
					error = new Error "Resource not found."
					error.code = 404
				
				Q.reject error
			
			Model.authenticatedFind user, id
		
	Model::isAccessibleBy ?= (user) -> true
	Model::isEditableBy ?= (user) -> false
	Model::isDeletableBy ?= (user) -> false
	Model::redactFor ?= (user) -> Q.resolve this

exports.$modelsAlter = (models) ->
	
	augmentModel models.User, Model, name for name, Model of models
		
exports.$service = [
	'$q', 'config', 'core', 'rpc', 'schema'
	($q, config, core, rpc, schema) ->
		
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

exports[path] = require "packages/user/#{path}" for path in [
	'forgot', 'login', 'logout', 'register', 'reset'
]
