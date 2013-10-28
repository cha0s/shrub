
crypto = require 'server/crypto'
{models: User: User} = require 'server/jugglingdb'

module.exports = (req, data, fn) ->
	
	user = new User name: data.username

	# Encrypt the email.	
	crypto.encrypt data.email, (error, encryptedEmail) ->
		fn error if error?
	
		user.email = encryptedEmail
		
		# Generate hash salt.
		User.randomHash (error, salt) ->
			fn error if error?
			
			user.salt = salt
			
			# Don't reveal anything beyond any error.
			user.save (error, user) -> fn error