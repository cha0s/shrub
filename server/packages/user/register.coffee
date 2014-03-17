
crypto = require 'server/crypto'

{threshold} = require 'limits'

exports.$endpoint = ->

	limiter:
		message: "You are trying to register too much."
		threshold: threshold(1).every(2).minutes()

	receiver: (req, fn) ->
		
		{body} = req
		{email, password, username} = body
		
		exports.register(username, email, password).then((user) ->
		
			# TODO: email with password ? opts.plaintext 
		
		).nodeify fn
		
exports.$replContext = (context) ->
	
	schema = require 'server/jugglingdb'
	
	context.registerUser = (name, email, password) ->
	
		_register name, email, password, schema

exports.register = (name, email, password) ->
	
	_register name, email, password, require 'server/jugglingdb'
	
_register = (name, email, password, schema) ->
	
	{models: User: User} = schema
	user = new User name: name
	
	# Encrypt the email.
	crypto.encrypt(email).then((encryptedEmail) ->

		user.email = encryptedEmail

		crypto.hasher plaintext: password
		
	).then((opts) ->

		user.salt = opts.salt.toString 'hex'
		user.passwordHash = opts.key.toString 'hex'

		user.save()
	
	)
