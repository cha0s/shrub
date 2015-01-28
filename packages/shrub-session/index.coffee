
# # Session
#
# Various means for dealing with sessions.

Promise = require 'bluebird'

config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `fingerprint`
	registrar.registerHook 'fingerprint', (req) ->

		# Session ID.
		session: if req?.session? then req.session.id

	# ## Implements hook `endpointFinished`
	registrar.registerHook 'endpointFinished', (routeReq, result, req) ->
		return unless routeReq.session?

		# Touch and save the session after every RPC call finishes.
		deferred = Promise.defer()
		routeReq.session.touch().save deferred.callback

		# Propagate changes back up to the original request.
		deferred.promise.then -> req.session = routeReq.session

	# ## Implements hook `packageSettings`
	registrar.registerHook 'packageSettings', ->

		# Session store instance.
		sessionStore: 'redis'

		# Key within the cookie where the session is stored.
		key: 'connect.sid'

		# Cookie information.
		cookie:

			# The crypto key we encrypt the cookie with.
			cryptoKey: '***CHANGE THIS***'

			# The max age of this session. Defaults to two weeks.
			maxAge: 1000 * 60 * 60 * 24 * 14

	# ## Implements hook `socketConnectionMiddleware`
	registrar.registerHook 'socketConnectionMiddleware', ->

		label: 'Join channel for session'
		middleware: [

			(req, res, next) ->

				return req.socket.join session.id, next if session?

				next()

		]
