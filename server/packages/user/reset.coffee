
crypto = require 'server/crypto'

{threshold} = require 'limits'

exports.$endpoint = ->

	limiter: threshold: threshold(1).every(5).minutes()

	receiver: (req, fn) ->
		
		{models: User: User} = require 'server/jugglingdb'
		
		filter = where: resetPasswordToken: req.body.token
		
		(User.findOne filter).then((user) ->
			return unless user?
			
			User.hashPassword(
				req.body.password, user.salt
			
			).then (passwordHash) ->
				user.passwordHash = passwordHash
				user.resetPasswordToken = null
				user.save()
	
		).then(->
			
			# Make it impossible to tell whether an invalid token was used.
			return
	
		).nodeify fn
