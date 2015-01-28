
# # Express routes

express = require 'express'
redis = require 'redis'
signature = require 'cookie-signature'

config = require 'config'

sessionPackage = require './index'

cookieParser = null
sessionStore = null

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `bootstrapMiddleware`
	registrar.registerHook 'bootstrapMiddleware', ->

		label: 'Bootstrap session handling'
		middleware: [

			(next) ->

				{cookie, sessionStore: sessionStoreConfig} = config.get(
					'packageSettings:shrub-session'
				)

				cookieParser = express.cookieParser cookie.cryptoKey

				sessionStore = switch sessionStoreConfig

					when 'redis'

						RedisStore = require('connect-redis') express
						new RedisStore client: redis.createClient()

				next()

		]

	# ## Implements hook `httpMiddleware`
	#
	# Parse cookies and load any session.
	registrar.registerHook 'httpMiddleware', (http) ->

		{cookie, key} = config.get 'packageSettings:shrub-session'

		label: 'Load session from cookie'
		middleware: [

			# Express cookie parser.
			-> cookieParser arguments...

			# Session reification.
			express.session(
				key: key
				store: sessionStore
				cookie: cookie
			)

			# If this is the first request made by a client, the cookie won't exist
			# in req.headers.cookie. We normalize that inconsistency, so all
			# consumers of the cookie will have a consistent interface on the first
			# as well as subsequent requests.
			(req, res, next) ->

				# } If the client is in sync, awesome!
				return next() if req.signedCookies[key] is req.sessionID

				# } Generate the cookie
				val = "s:" + signature.sign req.sessionID, cookie.cryptoKey
				cookieText = req.session.cookie.serialize key, val

				cookieObject = {}
				for kv in cookieText.split ';'
					[k, v] = kv.split '='
					cookieObject[k.trim()] = v

				# } Pull out junk that only makes sense en route to client.
				delete cookieObject['Path']
				delete cookieObject['HttpOnly']

				# } Rebuild the cookie string.
				cookieText = ''
				for k, v of cookieObject
					cookieText += '; ' if cookieText
					cookieText += k + '=' + v

				# } Commit the session before offering the cookie, otherwise it
				# } wouldn't actually be pointing at anything yet.
				req.session.save (error) ->
					next error if error?

					req.signedCookies[key] = req.sessionID
					req.headers.cookie = cookieText
					next()

		]

	# ## Implements hook `socketAuthorizationMiddleware`
	registrar.registerHook 'socketAuthorizationMiddleware', ->

		{key} = config.get 'packageSettings:shrub-session'

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
