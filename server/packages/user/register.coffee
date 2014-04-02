
# # User registration

config = require 'config'
nodemailer = require 'server/packages/nodemailer'

crypto = require 'server/crypto'
schema = require 'schema'

{threshold} = require 'limits'

# ## Implements hook `endpoint`
exports.$endpoint = ->

	limiter:
		message: "You are trying to register too much."
		threshold: threshold(5).every(2).minutes()

	receiver: (req, fn) ->
		
		{body} = req
		{email, password, username} = body
		
		# Register a new user.
		exports.register(username, email, password).then((user) ->
			
			# Send an email to the new user's email with a one-time login
			# link.
			hostname = "http://#{
				req.headers.host
			}"
			
			siteName = config.get 'packageSettings:core:siteName'
			
			tokens =
				
				hostname: hostname
				
				email: email
				
				loginUrl: "#{
					hostname
				}/user/reset/#{
					user.resetPasswordToken
				}"
				
				password: user.plaintext
				
				siteName: siteName
				
				title: "Account registration details"
				
				username: username
			
			nodemailer.sendMail(
				'user/register'
				to: email
				subject: "Account registration details for #{siteName}"
				tokens: tokens
			)
		
		).then(
			-> fn()
			(error) -> fn error
		)
		
# ## Implements hook `replContext`
exports.$replContext = (context) ->
	
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
exports.register = (name, email, password) ->
	
	{User} = schema.models
	user = new User name: name, iname: name.toLowerCase()
	
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
