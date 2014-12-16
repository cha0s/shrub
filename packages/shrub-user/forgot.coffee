
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
				
				# Generate a one-time login token.
				crypto.randomBytes 24
				
			).then((token) ->
				return unless @user?
				
				@user.resetPasswordToken = token.toString 'hex'
				
				# Decrypt the user's email address.
				crypto.decrypt @user.email
				
			).then((email) ->
				
				# Send an email to the user with a one-time login link.
				hostname = "http://#{
					req.headers.host
				}"
				
				siteName = config.get 'packageSettings:shrub-core:siteName'
				
				tokens =
					
					hostname: hostname
					
					email: email
					
					loginUrl: "#{
						hostname
					}/user/reset/#{
						@user.resetPasswordToken
					}"
					
					siteName: siteName
					
					title: "Password recovery request"
					
					username: @user.name
				
				nodemailer.sendMail(
					'user/forgot'
					to: email
					subject: "Password recovery request for your account at #{
						siteName
					}"
					tokens: tokens
				)
			
				@user.save()
		
			).then(->
				
				fn()
				
			).catch fn
