
crypto = require 'server/crypto'
{models: User: User} = require 'server/jugglingdb'

module.exports = (req, data, fn) ->
	
	# Search for username or encrypted email.
	if -1 is data.usernameOrEmail.indexOf '@'
		filter = where: name: data.usernameOrEmail
	else
		filter = where: email: crypto.encrypt data.usernameOrEmail
	
	# fn() won't reveal anything.
	# Find the user.
	User.findOne filter, (error, user) ->
		return fn() if error?
		return fn() unless user
		
		# Generate a one-time login token.
		User.randomHash (error, hash) ->
			return fn() if error?
			
			user.resetPasswordToken = hash
			user.save ->
				
				# This would be where we send an email to the user notifying
				# them of the URL they can visit to reset their password.
				
				fn()
