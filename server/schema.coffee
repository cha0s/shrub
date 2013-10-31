
nconf = require 'nconf'

exports.define = (adapter, options = {}) ->
	
	options.cryptoKey = nconf.get 'cryptoKey'
	
	{
		models:
			User: User
	} = schema = require('schema').define(
		require('jugglingdb').Schema
		adapter
		options
	)
	
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
	
	User::redact = ->
		
		@passwordHash = null
		@resetPasswordToken = null
		@salt = null
		
		this
	
	# Hax.
	schema.adapter.own = schema.adapter.all
	
	schema
