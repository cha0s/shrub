
# # User - forgot password

Promise = require 'bluebird'

crypto = require 'server/crypto'
config = require 'config'

nodemailer = require 'shrub-nodemailer'
orm = require 'shrub-orm'

{threshold} = require 'limits'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `endpoint`
	registrar.registerHook 'endpoint', ->

		limiter: threshold: threshold(1).every(30).seconds()

		route: 'shrub.user.forgot'

		receiver: (req, fn) ->

			User = orm.collection 'shrub-user'

			# Cancel promise flow if the user doesn't exist.
			class NoSuchUser extends Error
				constructor: (@message) ->

			# Look up the user.
			Promise.resolve().then(->

				# Search for username or encrypted email.
				if -1 is req.body.usernameOrEmail.indexOf '@'

					iname: req.body.usernameOrEmail.toLowerCase()

				else

					crypto.encrypt(
						req.body.usernameOrEmail.toLowerCase()

					).then (encryptedEmail) -> email: encryptedEmail

			).then((filter) ->

				# Find the user.
				User.findOne filter

			).then((@user) ->
				throw new NoSuchUser unless @user?

				# Generate a one-time login token.
				crypto.randomBytes 24

			).then((token) ->

				@user.resetPasswordToken = token.toString 'hex'

				# Decrypt the user's email address.
				crypto.decrypt @user.email

			).then((email) ->

				# Send an email to the user's email with a one-time login
				# link.
				siteHostname = config.get 'packageSettings:shrub-core:siteHostname'
				siteUrl = "http://#{siteHostname}"

				scope =

					email: email

					# `TODO`: HTTPS
					loginUrl: "#{
						siteUrl
					}/user/reset/#{
						user.resetPasswordToken
					}"

					siteUrl: siteUrl

					user: @user

				nodemailer.sendMail(
					'shrub-user-email-forgot'
				,
					to: email
					subject: "Password recovery request"
				,
					scope
				)

				@user.save()

			).then(-> fn()

			).catch(NoSuchUser, -> fn()

			).catch fn
