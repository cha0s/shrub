
# # Villiany
#
# Watch for and punish bad behavior.

i8n = null
Promise = null

logger = null

orm = null

villianyLimiter = null

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `preBootstrap`
	registrar.registerHook 'preBootstrap', ->

		i8n = require 'inflection'
		Promise = require 'bluebird'

		logging = require 'logging'

		orm = require 'shrub-orm'

		logger = logging.create 'logs/villiany.log'

		{Limiter} = require 'shrub-limiter'

		villianyLimiter = new Limiter(
			'villiany', Limiter.threshold(1000).every(10).minutes()
		)

	# ## Implements hook `endpointAlter`
	registrar.registerHook 'endpointAlter', (endpoints) ->
		for route, endpoint of endpoints
			endpoint.villianyScore ?= 20

	# ## Implements hook `collections`
	registrar.registerHook 'collections', ->

		audit = require 'shrub-audit'

		# Bans.
		Ban = attributes: expires: 'date'

		# The structure of a ban is dictated by the fingerprint structure.
		audit.Fingerprint.keys().forEach (key) ->
			Ban.attributes[key] =
				index: true
				type: 'string'

			# Generate a test for whether each fingerprint key has been banned.
			# `session` -> `isSessionBanned`
			Ban[i8n.camelize "is_#{key}_banned", true] = (value) ->
				method = i8n.camelize "find_by_#{key}", true
				Promise.cast(this[method] value).bind({}).then((@bans) ->
					return false if @bans.length is 0

					# Destroy all expired bans.
					expired = @bans.filter (ban) ->
						ban.expires.getTime() <= Date.now()
					Promise.all expired.map (ban) -> ban.destroy()

				).then (expired) ->

					_ = require 'lodash'

					# More bans than those that expired?
					isBanned: @bans.length > expired.length

					# Ban ttl.
					ttl: Math.round (_.difference(@bans, expired).reduce(
						(l, r) ->

							if l > r.expires.getTime()
								l
							else
								r.expires.getTime()

						-Infinity

					# It's a timestamp, and it's in ms.
					) - Date.now()) / 1000

		# Create a ban from a fingerprint.
		Ban.createFromFingerprint = (fingerprint, expires) ->

			config = require 'config'

			unless expires?
				settings = config.get 'packageSettings:shrub-villiany:ban'
				expires = parseInt settings.defaultExpiration

			data = expires: new Date Date.now() + expires
			data[key] = value for key, value of fingerprint
			@create data

		'shrub-ban': Ban

	# ## Implements hook `httpMiddleware`
	registrar.registerHook 'httpMiddleware', ->

		label: 'Provide villiany management'
		middleware: [

			(req, res, next) ->

				req.villianyKick = (subject, ttl) ->

					# Destroy any session.
					req.session?.destroy()

					# Log the user out.
					req.logOut().then ->

						res.status 401
						res.end buildBanMessage subject, ttl

				next()

			reporterMiddleware

			enforcementMiddleware

		]

	# ## Implements hook `settings`
	registrar.registerHook 'packageSettings', ->

		ban:

			# 10 minute ban time by default.
			defaultExpiration: 1000 * 60 * 10

	# ## Implements hook `socketAuthorizationMiddleware`
	registrar.registerHook 'socketAuthorizationMiddleware', ->

		{AuthorizationFailure} = require 'shrub-socket/manager'

		label: 'Provide villiany management'
		middleware: [

			(req, res, next) ->

				req.villianyKick = (subject, ttl) ->

					# Destroy any session.
					req.session?.destroy()

					# Log the user out.
					req.logOut().then ->

						# Not already authorized?
						throw new AuthorizationFailure unless req.socket?

						req.socket.emit 'core.reload'


				next()

			reporterMiddleware

			enforcementMiddleware

		]

# Define `req.reportVilliany()`.
reporterMiddleware = (req, res, next) ->

	Ban = orm.collection 'shrub-ban'

	req.reportVilliany = (score, type, excluded = []) ->

		# Terminate the chain if not a villian.
		class NotAVillian extends Error
			constructor: (@message) ->

		inlineKeys = req.fingerprint.inlineKeys excluded

		villianyLimiter.accrueAndCheckThreshold(
			inlineKeys, score

		).then((isVillian) ->

			# Log this transgression.
			fingerprint = req.fingerprint.get excluded
			message = "Logged villiany score #{
				score
			} for #{
				type
			}, audit keys: #{
				JSON.stringify fingerprint
			}"
			message += ', which resulted in a ban.' if isVillian
			logger[if isVillian then 'error' else 'warn'] message

			throw new NotAVillian unless isVillian

			# Ban.
			Ban.createFromFingerprint fingerprint

		).then(->

			# Kick.
			req.villianyKick villianyLimiter.ttl inlineKeys

		).then(-> true).catch NotAVillian, -> false

	next()

# Enforce bans.
enforcementMiddleware = (req, res, next) ->

	Ban = orm.collection 'shrub-ban'

	# Terminate the request if a ban is enforced.
	class RequestBanned extends Error
		constructor: (@message) ->

	banPromises = for key, value of req.fingerprint.get()
		do (key, value) ->
			method = i8n.camelize "is_#{key}_banned", true
			Ban[method](value).then ({isBanned, ttl}) ->
				return unless isBanned
				req.villianyKick(key, ttl).then -> throw new RequestBanned()

	Promise.all(banPromises).then(-> next()).catch(

		# Ignore the error when it's only signifying a ban.
		RequestBanned, ->
	).catch (error) -> next error

# Build a nice message for the villian.
buildBanMessage = (subject, ttl) ->

	moment = require 'moment'

	message = if subject?
		"Your #{subject} is banned."
	else
		'You are banned.'

	message += " The ban will be lifted #{
		moment().add('seconds', ttl).fromNow()
	}." if ttl?

	message
