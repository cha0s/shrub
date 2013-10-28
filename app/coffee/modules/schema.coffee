
## The database schema

access = require 'access'
i8n = require 'inflection'

exports.define = (Schema, adapter, options = {}) ->
	
	schema = new Schema adapter, options
	
	# Translate model names to REST resource/collection paths.
	# 'CatalogEntry' -> ['catalog-entry', 'catalog-entries']
	schema.resourcePaths = (name) ->
	
		resource = i8n.underscore name
		resource = i8n.dasherize resource.toLowerCase()
		
		resource: resource
		collection: i8n.pluralize resource
	
	User = access.wrapModel schema.define 'User',
		
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
			
	User.randomHash = (fn) ->
		return fn new Error(
			"No crypto support."
		) unless options.cryptoKey?
		
		require('crypto').randomBytes 24, (error, buffer) ->
			return fn error if error?
			
			fn null, require('crypto').createHash('sha512').update(
				options.cryptoKey
			).update(
				buffer.toString()
			).digest 'hex'
	
	User.hashPassword = (password, salt, fn) ->
		return fn new Error(
			"No crypto support."
		) unless options.cryptoKey?
		
		require('crypto').pbkdf2 password, salt, 20000, 512, fn
	
	User::hasPermission = (perm) -> true
	
	User::redact = ->
		
		@passwordHash = null
		@resetPasswordToken = null
		@salt = null
		
		this
	
	# TODO should be config, not hardcoded...	
	schema.root = '/api'

	schema
