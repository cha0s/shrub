
crypto = require 'server/crypto'

exports.$endpoint = (req, fn) ->
	
	{models: User: User} = require 'server/jugglingdb'
	
	filter = where: resetPasswordToken: req.body.token
	
	# It may seem strange that we merely invoke fn() instead of sending
	# useful data to the client, but the reasoning behind this is to make it
	# impossible to tell whether an invalid token was used.
	(User.findOne filter).then((user) ->
		return Q.resolve() unless user?
		
		User.hashPassword req.body.password, user.salt

	).then((passwordHash) ->

		user.passwordHash = passwordHash
		user.resetPasswordToken = null
		user.save()

	).nodeify fn
