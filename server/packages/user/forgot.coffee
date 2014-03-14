
crypto = require 'server/crypto'
Q = require 'bluebird'

{threshold} = require 'limits'

exports.$endpoint =

	limiter: threshold: threshold(1).every(30).seconds()

	receiver: (req, fn) ->
		
		{models: User: User} = require 'server/jugglingdb'
		
		Q.resolve().then(->
		
			# Search for username or encrypted email.
			if -1 is req.body.usernameOrEmail.indexOf '@'
				
				where: name: req.body.usernameOrEmail
			
			else
				
				crypto.encrypt(
					req.body.usernameOrEmail
				
				).then (encryptedEmail) ->
					where: email: encryptedEmail
		
		).then((filter) ->
			
			# Find the user.
			User.findOne filter
			
		).then((@user) ->
			
			# Generate a one-time login token.
			User.randomHash()
			
		).then((hash) ->
			return Q.resolve() unless @user?
			
			user.resetPasswordToken = hash
			user.save()
	
		).nodeify fn
