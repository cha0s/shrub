
crypto = require 'server/crypto'

{threshold} = require 'limits'

exports.$endpoint = ->

	limiter:
		message: "You are trying to register too much."
		threshold: threshold(1).every(2).minutes()

	receiver: (req, fn) ->
		
		{models: User: User} = require 'server/jugglingdb'
		
		user = new User name: req.body.username
		
		# Encrypt the email.
		(crypto.encrypt req.body.email).then((encryptedEmail) ->
		
			user.email = encryptedEmail
			
			crypto.hasher()
			
		).then((opts) ->
	
			user.salt = opts.salt.toString 'hex'
			user.passwordHash = opts.key.toString 'hex'
			
			# TODO: email req.body.email with opts.plaintext 
		
			user.save()
		
		).nodeify fn
