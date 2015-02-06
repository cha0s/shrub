
# # User password reset

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `endpoint`
	registrar.registerHook 'endpoint', ->

		crypto = require 'server/crypto'

		Promise = require 'bluebird'

		{Limiter} = require 'shrub-limiter'
		orm = require 'shrub-orm'

		limiter: threshold: Limiter.threshold(1).every(5).minutes()
		route: 'shrub.user.reset'

		receiver: (req, fn) ->

			User = orm.collection 'shrub-user'

			# Cancel promise flow if the user doesn't exist.
			class NoSuchUser extends Error
				constructor: (@message) ->

			# Look up the user.
			Promise.cast(
				User.findOne resetPasswordToken: req.body.token
			).bind({}).then((@user) ->
				throw new NoSuchUser unless @user?

				# Recalculate the password hashing details.
				crypto.hasher plaintext: req.body.password

			).then((hashed) ->

				@user.passwordHash = hashed.key.toString 'hex'
				@user.salt = hashed.salt.toString 'hex'
				@user.resetPasswordToken = null

				@user.save()

			).then(-> fn()).catch(NoSuchUser, -> fn()).catch fn
