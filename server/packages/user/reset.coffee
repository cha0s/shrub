
# # User password reset

crypto = require 'server/crypto'

{threshold} = require 'limits'
schema = require 'server/jugglingdb'

# ## Implements hook `endpoint`
exports.$endpoint = ->

	limiter: threshold: threshold(1).every(5).minutes()

	receiver: (req, fn) ->
		
		{User} = schema.models
		
		# Look up the user.
		User.findOne(
			where: resetPasswordToken: req.body.token
		
		).bind({}).then((@user) ->
			return unless @user?
			
			# Recalculate the password hashing details.
			crypto.hasher plaintext: req.body.password
			
		).then((hashed) ->
		
			@user.passwordHash = hashed.key.toString 'hex'
			@user.salt = hashed.salt.toString 'hex'
			@user.resetPasswordToken = null
			@user.save()
			
		).then(->
			
			# Make it impossible to tell whether an invalid token was used.
			return
	
		).nodeify fn
