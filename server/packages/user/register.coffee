
nconf = require 'nconf'
nodemailer = require 'server/packages/nodemailer'

crypto = require 'server/crypto'

{threshold} = require 'limits'

exports.$endpoint = ->

	limiter:
		message: "You are trying to register too much."
		threshold: threshold(5).every(2).minutes()

	receiver: (req, fn) ->
		
		{body} = req
		{email, password, username} = body
		
		exports.register(username, email, password).then((user) ->
			
			baseUrl = "http://#{
				req.headers.host
			}"
			
			siteName = nconf.get 'siteName'
			
			tokens =
				
				baseUrl: baseUrl
				
				email: email
				
				loginUrl: "#{
					baseUrl
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
		
exports.$replContext = (context) ->
	
	schema = require 'server/jugglingdb'
	
	context.registerUser = (name, email, password) ->
	
		_register name, email, password, schema

exports.register = (name, email, password) ->
	
	_register name, email, password, require 'server/jugglingdb'
	
_register = (name, email, password, schema) ->
	
	{models: User: User} = schema
	user = new User name: name, iname: name.toLowerCase()
	
	# Encrypt the email.
	crypto.encrypt(email.toLowerCase()).then((encryptedEmail) ->

		user.email = encryptedEmail

		crypto.hasher plaintext: password
		
	).then((opts) ->
		
		user.plaintext = opts.plaintext
		user.salt = opts.salt.toString 'hex'
		user.passwordHash = opts.key.toString 'hex'
	
		# Generate a one-time login token.
		crypto.randomBytes 24
		
	).then((token) ->
		
		user.resetPasswordToken = token.toString 'hex'
		
		user.save()
	
	)
