
# # Rate limiter
#
# Limits the rate at which clients can do certain operations, like call RPC
# endpoints.

moment = require 'moment'
Promise = require 'bluebird'

audit = require 'audit'
errors = require 'errors'
middleware = require 'middleware'
pkgman = require 'pkgman'

{Limiter, threshold} = require 'limits'

exports.SKIP = SKIP = 0
exports.IGNORE = IGNORE = 1

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `collections`
	registrar.registerHook 'collections', ->

		'shrub-limit':

			attributes:

				# The limiter key.
				key:
					type: 'string'
					index: true

				# Scores accrued for this limit.
				scores:
					type: 'array'
					defaultsTo: []

	# ## Implements hook `endpointAlter`
	#
	# Allow RPC endpoint definitions to specify rate limiters.
	registrar.registerHook 'endpointAlter', (endpoints) ->

		# Invoke hook `limiterApplicationMiddleware`.
		# Invoked when a limit is applied.
		limiterApplicationMiddleware = middleware.fromShortName(
			'limiter application'
			'shrub-limiter'
		)

		# A limiter on a route is defined like:
		#
		# * `message`: The message returned to the client when the threshold is
		#   passed.
		#
		# * `threshold`: The
		#   [threshold](http://shrub.doc.com.dev/server/limits.html#threshold) for
		#   this limiter.
		#
		# * `ignoreKeys`: The
		#   [audit keys](http://shrub.doc.com.dev/hooks.html#fingerprint) to ignore
		#   when determining the total limit. In this example, the IP address and
		#   session ID would be ignored.

		Object.keys(endpoints).forEach (route) ->
			endpoint = endpoints[route]

			# } No limter? Nevermind...
			return unless endpoint.limiter?

			# Create a limiter based on the threshold defined.
			endpoint.limiter.instance = new Limiter(
				"rpc://#{route}"
				endpoint.limiter.threshold
			)

			# Set defaults.
			endpoint.limiter.ignoreKeys ?= []
			endpoint.limiter.message ?= "You are doing that too much."

			# Add a validator, where we'll check the threshold.
			endpoint.validators.push (req, res, next) ->

				{ignoreKeys, instance} = endpoint.limiter

				# Ignore keys.
				fingerprint = audit.fingerprint req
				delete fingerprint[excludedKey] for excludedKey in ignoreKeys

				keys = ("#{key}:#{value}" for key, value of fingerprint)

				for rule in pkgman.invokeFlat 'limiterCheck', req, endpoint, keys
					continue unless rule?
					return next() if SKIP is rule

				# Accrue a hit and check the threshold.
				instance.accrueAndCheckThreshold(keys).then((isLimited) ->
					return next() unless isLimited

					# Don't pass req directly, since it can be mutated by
					# routes, and violate other routes' expectations.
					limiterReq = {}
					limiterReq[key] = value for key, value of req
					limiterReq.endpoint = endpoint
					limiterReq.keys = keys
					limiterReq.route = route

					limiterApplicationMiddleware.dispatch limiterReq, null, (error) ->
						return next error if error?
						next()

				).catch next

	# ## Implements hook `transmittableError`
	#
	# Just defer to client, where the error is defined.
	registrar.registerHook 'transmittableError', require('./client').transmittableError

	# ## Implements hook `packageSettings`
	registrar.registerHook 'packageSettings', ->

		applicationMiddleware: [
			'shrub-villiany'
		]
