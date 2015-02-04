
# # Limits

Promise = require 'bluebird'

pkgman = require 'pkgman'

orm = require 'shrub-orm'

# ## Limiter
#
# Provides methods to tally scores, and compare them against a threshold of
# time.
#
# The [limiter](./packages/limiter/index.html) package implements hook
# `endpointAlter` to allow RPC endpoints to limit consumers to a specified
# number of requests per time period. For instance, by default the
# [user login](./packages/user/login.html) endpoint limits the number of logins
# a user may attempt to 3 every 30 seconds.
# `TODO`: Rewrite this comment
module.exports = class Limiter

	# ## threshold
	#
	# Expose a factory method for constructing Threshold instances. A
	# Threshold is defined like:
	#
	# 	{Limiter} = require 'shrub-limiter'
	# 	Limiter.threshold(4).every(20).minutes()
	#
	# Which means that the threshold represents the allowance of a score of 4
	# to accumulate over the period of 20 minutes. If more score is accrued
	# during that window, then the threshold is said to be crossed.
	@threshold: (score) -> new ThresholdBase score

	# ### *constructor*
	#
	# *Create a limiter.*
	#
	# * (string) `key` - A unique key for this limiter,
	#   e.g. "rpc://user.login:limiter"
	#
	# * (Threshold) `threshold` - A threshold, see below for details.
	constructor: (key, @threshold, @excluded = []) ->

		# } Make sure it's a threshold.
		throw new TypeError(
			"Limiter(#{key}) must be constructed with a valid threshold!"
		) unless @threshold instanceof ThresholdFinal

		# } Create the low-level limiter.
		@limiter = new LimiterManager key, @threshold.calculateSeconds()

	# ### .add
	#
	# *Accrue score for a limiter.*
	#
	# * (array) `keys` - An array of keys, e.g. a flattened array of keys
	#   from [`audit.fingerprint()`](./audit.html)
	#
	# * (integer) `score` - The score to add. Defaults to 1.
	accrue: (keys, score = 1) ->
		Promise.all (@limiter.accrue key, score for key in keys)

	# ### .accrueAndCheckThreshold
	#
	# *Add score to a limiter, and check it against the threshold.*
	#
	# * (array) `keys` - An array of keys, e.g. a flattened array of keys
	#   from [`audit.fingerprint()`](./audit.html)
	#
	# * (integer) `score` - The score to add. Defaults to 1.
	accrueAndCheckThreshold: (keys, score = 1) ->
		@accrue(keys, score).then => @checkThreshold keys

	# ### .score
	#
	# *Check score for a limiter.*
	#
	# * (array) `keys` - An array of keys, e.g. a flattened array of keys
	#   from [`audit.fingerprint()`](./audit.html)
	score: (keys) -> @_largest keys, 'score'

	# ### .ttl
	#
	# *Time-to-live for a limiter.*
	#
	# * (array) `keys` - An array of keys, e.g. a flattened array of keys
	#   from [`audit.fingerprint()`](./audit.html)
	ttl: (keys) -> @_largest keys, 'ttl'

	# ### .checkThreshold
	#
	# *Check the current limiter score against the threshold.*
	#
	# * (array) `keys` - An array of keys, e.g. a flattened array of keys
	#   from [`audit.fingerprint()`](./audit.html)
	checkThreshold: (keys) ->
		@score(keys).then (score) => score > @threshold.score()

	# #### ._largest
	#
	# (internal) *Find the largest result from a group of results.*
	_largest: (keys, index) ->

		Promise.all(
			@limiter[index] key for key in keys

		).then (reduction) ->
			reduction.reduce ((l, r) -> if l > r then l else r), -Infinity

class LimiterManager

	constructor: (@key, @thresholdWindow) ->

	# ### .add
	#
	# *Add score to a limiter.*
	#
	# * (string) `id` - The ID of the limiter.
	#
	# * (integer) `score` - The score to add. Defaults to 1.
	accrue: (id, score = 1) ->

		Limit = orm.collection 'shrub-limit'
		LimitScore = orm.collection 'shrub-limit-score'

		# } Cast score to integer.
		score = parseInt score, 10

		limitKey = "#{@key}:#{id}"
		Limit.findOrCreate(key: limitKey).populateAll().then (limit) =>
			limit.key = limitKey

			# } Accrue the score.
			addScore = ->
				limit.scores.add score: score
				limit.save()

			return addScore() unless @_limitHasExpired limit

			# } Empty out scores if it's expired.
			@_resetLimit(limit).then addScore

	# ### .score
	#
	# *Check score for a limiter.*
	#
	# * (string) `id` - The ID of the limiter.
	score: (id) ->

		Limit = orm.collection 'shrub-limit'
		LimitScore = orm.collection 'shrub-limit-score'

		# } Get all scores for this limiter.
		limitKey = "#{@key}:#{id}"
		Limit.findOne(key: limitKey).populateAll().then (limit) =>
			return 0 unless limit?

			# } Reset if it's expired.
			return @_resetLimit(limit).then(-> 0) if @_limitHasExpired limit

			# } Sum all the scores.
			limit.scores.map((model) -> model.score).reduce ((l, r) -> l + r), 0

	# ### .ttl
	#
	# *Time-to-live for a limiter.*
	#
	# * (string) `id` - The ID of the limiter.
	ttl: (id) ->

		limitKey = "#{@key}:#{id}"
		orm.collection('shrub-limit').findOne(key: limitKey).then (limit) =>
			return 0 unless limit?

			# } Reset if it's expired.
			return @_resetLimit(limit).then(-> 0) if @_limitHasExpired limit

			limit.key = limitKey
			limit.save().then =>

				diff = (Date.now() - limit.createdAt.getTime()) / 1000
				Math.ceil @thresholdWindow - diff

	_limitHasExpired: (limit) ->

		diff = (Date.now() - limit.createdAt.getTime()) / 1000
		diff >= @thresholdWindow

	_resetLimit: (limit) ->

		# } Remove all scores.
		for id in limit.scores.map((model) -> model.id)
			limit.scores.remove id

		limit.createdAt = new Date()
		limit.save()

# ## ThresholdBase
#
# The base class used to define a threshold.
class ThresholdBase

	# ### *constructor*
	#
	# *Create a threshold base object.*
	#
	# * (integer) `score` - The maximum score allowed to accrue.
	constructor: (@_score) ->

	# ### .every
	#
	# *Define the quantity of time this threshold concerns.*
	#
	# * (integer) `amount` - The quantity of time units this threshold
	#   concerns. e.g, if the threshold is every 5 minutes, this will be `5`.
	every: (amount) -> new ThresholdMultiplier @_score, amount

# ## ThresholdMultiplier
#
# A threshold class to collect the multiplier.
class ThresholdMultiplier

	# ### *constructor*
	#
	# *Create a threshold.*
	#
	# * (integer) `score` - Passed along from ThresholdBase.
	#
	# * (integer) `amount` - Passed along from ThresholdBase.
	constructor: (@_score, @_amount) ->

		@_multiplier = 1

	# Add a method for each multipler. This is this way just to DRY things up.
	multipliers =
		milliseconds: 1 / 1000
		seconds: 1
		minutes: 60

	for key, multiplier of multipliers
		do (key, multiplier) ->
			ThresholdMultiplier::[key] = ->
				@_multiplier = multiplier

				# } Return a finalized threshold.
				new ThresholdFinal @_score, @_amount, @_multiplier

# ## ThresholdFinal
#
# A finalized threshold definition.
class ThresholdFinal

	# ### *constructor*
	#
	# *Create a threshold.*
	#
	# * (integer) `score` - Passed along from ThresholdMultiplier.
	#
	# * (integer) `amount` - Passed along from ThresholdMultiplier.
	#
	# * (integer) `multiplier` - Passed along from ThresholdMultiplier.
	constructor: (score, amount, multiplier) ->

		@calculateSeconds = -> amount * multiplier
		@score = -> score
