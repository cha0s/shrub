
# # User registration

config = require 'config'
nodemailer = require 'shrub-nodemailer'

crypto = require 'server/crypto'

orm = require 'shrub-orm'

{threshold} = require 'limits'

exports.pkgmanRegister = (registrar) ->
	
	# ## Implements hook `endpoint`
	registrar.registerHook 'endpoint', ->
	
		limiter:
			message: "You are trying to register too much."
			threshold: threshold(5).every(2).minutes()
		
		route: 'shrub.user.register'
		
		receiver: (req, fn) ->
			
			{body} = req
			{email, password, username} = body
			
			# Register a new user.
			exports.register(username, email, password).then((user) ->
				
				# Send an email to the new user's email with a one-time login
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
					
					user: user
				
				orm.collection('shrub-ui-notification').createFromRequest(
					req, 'shrubExampleGeneral'
					type: 'register'
					name: user.name
					email: email
				)
				
				nodemailer.sendMail(
					'shrub-user-email-register'
				,
					to: email
					subject: "Registration details"
				,
					scope
				)
				
				return
			
			).then(-> fn()
				
			).catch fn
			
	# ## Implements hook `replContext`
	registrar.registerHook 'replContext', (context) ->
		
		context.registerUser = exports.register
	
# ## register
# 
# *Register a user in the system.*
# 
# * (string) `name` - Name of the new user.
# 
# * (string) `email` - Email address of the new user.
# 
# * (string) `password` - The new user's password.
# 
# `TODO`: Should be a class method on the shrub-user collection.
exports.register = (name, email, password) ->
	
	User = orm.collection 'shrub-user'
	User.create(name: name, iname: name.toLowerCase()).then((user) ->
	
		# Encrypt the email.
		crypto.encrypt(email.toLowerCase()).then((encryptedEmail) ->
	
			user.email = encryptedEmail
	
			# Set the password encryption details.
			crypto.hasher plaintext: password
			
		).then((hashed) ->
			
			user.plaintext = hashed.plaintext
			user.salt = hashed.salt.toString 'hex'
			user.passwordHash = hashed.key.toString 'hex'
		
			# Generate a one-time login token.
			crypto.randomBytes 24
			
		).then (token) ->
			
			user.resetPasswordToken = token.toString 'hex'
			
			user.save()
	)
	
