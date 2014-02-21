
crypto = require 'server/crypto'

exports.$endpoint = (req, fn) ->
	
	{models: User: User} = require 'server/jugglingdb'
	
	user = new User name: req.body.username
	
	# Encrypt the email.
	(crypto.encrypt req.body.email).then((encryptedEmail) ->
	
		user.email = encryptedEmail
		
		User.randomHash()
	
	# Generate hash salt.
	).then((salt) ->

		user.salt = salt
		
		user.save()
	
	).nodeify fn
