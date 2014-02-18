
crypto = require 'server/crypto'
Q = require 'q'

{models: User: User} = require 'server/jugglingdb'

exports.$endpoint = (req, fn) ->
	
	deferred = Q.defer()
	
	# Search for username or encrypted email.
	if -1 is req.body.usernameOrEmail.indexOf '@'
		deferred.resolve where: name: req.body.usernameOrEmail
	else
		crypto.encrypt req.body.usernameOrEmail, (error, encryptedEmail) ->
			deferred.reject error if error?
			deferred.resolve where: email: encryptedEmail
	
	# fn() won't reveal anything.
	# Find the user.
	deferred.promise.then (filter) ->
		User.findOne filter, (error, user) ->
			return fn() if error?
			return fn() unless user
			
			# Generate a one-time login token.
			User.randomHash (error, hash) ->
				return fn() if error?
				
				user.resetPasswordToken = hash
				user.save ->
					
					# This would be where we send an email to the user
					# notifying them of the URL they can visit to reset
					# their password.
					
					fn()
					
	deferred.promise.fail (error) -> fn()				
