
# # Limits

Promise = require 'bluebird'
redis = require 'connect-redis/node_modules/redis'
redback = require('redback').use redis.createClient()

pkgman = require 'pkgman'

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
exports.Limiter = class Limiter
	
	# ### *constructor*
	# 
	# *Create a limiter.*
	# 
	# * (string) `key` - A unique key for this limiter,
	#   e.g. "rpc://user.login:limiter"
	# 
	# * (Threshold) `threshold` - A threshold, see below for details.
	# 
	# * (object) `options` - Limiter options
	#   `TODO`: This is gross API, just accept a limiter expiration window.
	constructor: (key, @threshold, options = {}) ->
		
		# } Make sure it's a threshold.
		throw new TypeError(
			"Limiter(#{key}) must be constructed with a valid threshold!"
		) unless @threshold instanceof ThresholdFinal
		
		# } `TODO`: This goes away.
		options.bucketTime ?= @threshold.calculateSeconds()
		
		# } Create the low-level redback limiter.
		@limiter = redback.createBetterRateLimit key, options
	
	# ### .add
	# 
	# *Add score to a limiter.*
	# 
	# `TODO`: This should be called `accrue`.
	# 
	# * (array) `keys` - An array of keys, e.g. a flattened array of keys
	#   from [`audit.keys()`](./audit.html)
	# 
	# * (integer) `score` - The score to add. Defaults to 1.
	add: (keys, score = 1) ->
		Promise.all(@limiter.add key, score for key in keys)
	
	# ### .addAndCheckThreshold
	# 
	# *Add score to a limiter, and check it against the threshold.*
	# 
	# `TODO`: This should be called `accrueAndCheckThreshold`.
	# 
	# * (array) `keys` - An array of keys, e.g. a flattened array of keys
	#   from [`audit.keys()`](./audit.html)
	# 
	# * (integer) `score` - The score to add. Defaults to 1.
	addAndCheckThreshold: (keys, score = 1) ->
		@add(keys, score).then => @checkThreshold keys
	
	# ### .count
	# 
	# *Check score for a limiter.*
	# 
	# `TODO`: This should be named `score`.
	# 
	# * (array) `keys` - An array of keys, e.g. a flattened array of keys
	#   from [`audit.keys()`](./audit.html)
	count: (keys) -> @_largest keys, 'count'
		
	# ### .ttl
	# 
	# *Time-to-live for a limiter.*
	# 
	# * (array) `keys` - An array of keys, e.g. a flattened array of keys
	#   from [`audit.keys()`](./audit.html)
	ttl: (keys) -> @_largest keys, 'ttl'
		
	# ### .checkThreshold
	# 
	# *Check the current limiter score against the threshold.*
	# 
	# * (array) `keys` - An array of keys, e.g. a flattened array of keys
	#   from [`audit.keys()`](./audit.html)
	checkThreshold: (keys) ->
		@count(keys).then (count) => count > @threshold.count()

	# #### ._largest
	# 
	# (internal) *Find the largest result from a group of results.*
	_largest: (keys, index) ->
	
		Promise.all(
			@limiter[index] key for key in keys
		
		).then (reduction) ->
			reduction.reduce ((l, r) -> if l > r then l else r), -Infinity

# ## ThresholdBase
# 
# The base class used to define a threshold.
class ThresholdBase
	
	# ### *constructor*
	# 
	# *Create a threshold base object.*
	# 
	# * (integer) `count` - The maximum score allowed to accrue.
	#   `TODO`: Rename this and all other usages to `score`.
	constructor: (@_count) ->
	
	# ### .every
	# 
	# *Define the quantity of time this threshold concerns.*
	# 
	# * (integer) `amount` - The quantity of time units this threshold
	#   concerns. e.g, if the threshold is every 5 minutes, this will be `5`. 
	every: (amount) -> new ThresholdFinal @_count, amount
	
# ## ThresholdFinal
# 
# A finalized threshold definition.
class ThresholdFinal
	
	# ### *constructor*
	# 
	# *Create a threshold.*
	# 
	# * (integer) `count` - Passed along from ThresholdBase.
	# 
	# * (integer) `amount` - Passed along from ThresholdBase.
	constructor: (@_count, @_amount) ->
		
		@_multiplier = 1
	
	# ### .calculateSeconds
	# 
	# *Calculate the threshold window in seconds.*
	calculateSeconds: -> @_amount * @_multiplier
	
	# ### .count
	# 
	# *The threshold score.*
	count: -> @_count
	
	# Add a method for each multipler. This is this way just to DRY things up.
	multipliers =
		milliseconds: 1 / 1000
		seconds: 1
		minutes: 60
	
	for key, multiplier of multipliers
		do (key, multiplier) =>
			@::[key] = ->
				@_multiplier = multiplier
				
				# } Return `this` to chain.
				# } `TODO`: This should instantiate a finalized Threshold class
				# } which cannot be chained, nor modified.
				this

# ## threshold
# 
# Expose a factory method for constructing Threshold instances. A Threshold is
# defined like:
# 
# 	{threshold} = require 'limits'
# 	threshold(4).every(20).minutes()
# 
# Which means that the threshold represents the allowance of a score of 4 to
# accumulate over the period of 20 minutes. If more score is accrued during
# that window, then the threshold is said to be crossed.
exports.threshold = (count) -> new ThresholdBase count
				
# Add a redback structure to handle rate limiting.
redback.addStructure(
	'BetterRateLimit'
	
	# Called by redback at initialization time: default to 10 minute window.
	# `TODO`: "bucketTime" is the WRONG symbol name.
	init: (options = {}) -> @bucketTime = options.bucketTime ? 60 * 10
	
	
	# ### .add
	# 
	# *Add score to a limiter.*
	# 
	# `TODO`: This should be called `accrue`.
	# 
	# * (string) `id` - The ID of the limiter.
	# * (integer) `score` - The score to add. Defaults to 1.
	add: (id, score = 1) ->
	
		# } Convenience.
		exists = Promise.promisify @client.exists, @client
		rpushx = Promise.promisify @client.rpushx, @client
		
		# } Cast score to integer.
		score = parseInt score, 10
		
		# } Add the ID to the end of the limiter key and check if an entry
		# } already exists.
		id = @key + ':' + id
		exists(id).bind(this).then (exists) ->
			
			# } Simply add it to the score if an entry already exists.
			return rpushx id, score if exists
			
			# } Otherwise, create an entry, add the score, and set the entry
			# } to expire.
			multi = @client.multi()
			multi.rpush id, score
			multi.expire id, @bucketTime
			Promise.promisify(multi.exec, multi)()
				
	# ### .count
	# 
	# *Check score for a limiter.*
	# 
	# `TODO`: This should be named `score`.
	# 
	# * (string) `id` - The ID of the limiter.
	count: (id) ->
	
		# } Convenience.
		lrange = Promise.promisify @client.lrange, @client
		
		# } Get all scores for this limiter.
		lrange(@key + ':' + id, 0, -1).then (counts) ->
			
			# } Sum all the scores.
			counts.reduce ((l, r) -> l + r), 0
		
	
	# ### .ttl
	# 
	# *Time-to-live for a limiter.*
	# 
	# * (string) `id` - The ID of the limiter.
	ttl: (id) -> Promise.promisify(@client.ttl, @client) @key + ':' + id
		
)
