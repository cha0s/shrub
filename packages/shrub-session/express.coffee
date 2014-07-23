
# # Express routes

express = require 'express'
redis = require 'redis'

config = require 'config'

sessionPackage = require './index'

# Session store.
sessionStore = null

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `httpMiddleware`
	# 
	# Parse cookies and load any session.
	registrar.registerHook 'httpMiddleware', (http) ->
		
		{cookie, key} = config.get 'packageSettings:shrub-session'
		
		cookieParser = express.cookieParser cookie.cryptoKey
		
		sessionStore = switch config.get 'packageSettings:shrub-session:sessionStore'
			
			when 'redis'
				
				RedisStore = require('connect-redis') express
				new RedisStore client: redis.createClient()
		
		label: 'Load session from cookie'
		middleware: [
			cookieParser
			
			express.session(
				key: key
				store: sessionStore
				cookie: cookie
			)
		]
	
	# ## Implements hook `socketAuthorizationMiddleware`
	registrar.registerHook 'socketAuthorizationMiddleware', ->
	
		{cookie, key} = config.get 'packageSettings:shrub-session'
		
		cookieParser = express.cookieParser cookie.cryptoKey
		
		label: 'Load session'
		middleware: [
		
			(req, res, next) ->
			
				# } Make sure there's a possibility we will find a session.
				return next() unless req and req.headers and req.headers.cookie
			
				cookieParser req, null, (error) =>
					return next error if error?
					
					# } Tricky: Assign req.sessionStore, because Express session
					# } functionality will be broken unless it exists.
					req.sessionStore = sessionStore
					sessionStore.load req.signedCookies[key], (error, session) ->
						return next error if error?
						return next() unless session?
						
						session.req = req
						req.session = session
						
						next()
				
		]
