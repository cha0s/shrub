
# # User password reset

crypto = require 'server/crypto'

{threshold} = require 'limits'

orm = require 'shrub-orm'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `endpoint`
	registrar.registerHook 'endpoint', ->
	
		limiter: threshold: threshold(1).every(5).minutes()
		route: 'shrub.user.reset'
	
		receiver: (req, fn) ->
			
			User = orm.collection 'shrub-user'
			
			# Look up the user.
			Promise.cast(
				User.findOne resetPasswordToken: req.body.token
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
