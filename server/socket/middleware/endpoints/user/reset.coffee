
crypto = require 'server/crypto'
{models: User: User} = require 'server/jugglingdb'

module.exports = (req, data, fn) ->
	
	filter = where: resetPasswordToken: data.token
	
	# It may seem strange that we merely invoke fn() instead of sending useful
	# data to the client, but the reasoning behind this is to make it
	# impossible to tell whether an invalid token was used.
	User.findOne filter, (error, user) ->
		return fn() if error?
		return fn() unless user
		
		User.hashPassword data.password, user.salt, (error, passwordHash) ->
			return fn() if error?
			
			user.passwordHash = passwordHash
			user.resetPasswordToken = null
			user.save -> fn()
