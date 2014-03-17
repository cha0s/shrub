
crypto = require 'server/crypto'

{threshold} = require 'limits'

exports.$endpoint = ->

	limiter: threshold: threshold(1).every(5).minutes()

	receiver: (req, fn) ->
		
		{models: User: User} = require 'server/jugglingdb'
		
		filter = where: resetPasswordToken: req.body.token
		
		(User.findOne filter).bind({}).then((@user) ->
			return unless @user?
			
			crypto.hasher plaintext: req.body.password
			
		).then((opts) ->
		
			@user.passwordHash = opts.key.toString 'hex'
			@user.salt = opts.salt.toString 'hex'
			@user.resetPasswordToken = null
			@user.save()
			
		).then(->
			
			# Make it impossible to tell whether an invalid token was used.
			return
	
		).nodeify fn
