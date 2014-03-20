
crypto = require 'server/crypto'
nconf = require 'nconf'
nodemailer = require 'server/packages/nodemailer'
Promise = require 'bluebird'

{threshold} = require 'limits'

exports.$endpoint = ->
	
	limiter: threshold: threshold(1).every(30).seconds()

	receiver: (req, fn) ->
		
		{models: User: User} = require 'server/jugglingdb'
		
		Promise.resolve().then(->
		
			# Search for username or encrypted email.
			if -1 is req.body.usernameOrEmail.indexOf '@'
				
				where: iname: req.body.usernameOrEmail.toLowerCase()
			
			else
				
				crypto.encrypt(
					req.body.usernameOrEmail.toLowerCase()
				
				).then (encryptedEmail) ->
					where: email: encryptedEmail
		
		).then((filter) ->
			
			# Find the user.
			User.findOne filter
			
		).then((@user) ->
			
			# Generate a one-time login token.
			crypto.randomBytes 24
			
		).then((token) ->
			return unless @user?
			
			@user.resetPasswordToken = token.toString 'hex'
			
			crypto.decrypt @user.email
			
		).then((email) ->
			
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
					@user.resetPasswordToken
				}"
				
				siteName: siteName
				
				title: "Password recovery request"
				
				username: @user.name
			
			nodemailer.sendMail(
				'user/forgot'
				to: email
				subject: "Password recovery request for your account at #{siteName}"
				tokens: tokens
			)
		
			@user.save()
	
		).then(->
			
			return
			
		).nodeify fn
