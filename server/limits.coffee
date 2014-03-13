
Promise = require 'bluebird'
redis = require 'connect-redis/node_modules/redis'
redback = require('redback').use redis.createClient()

pkgman = require 'pkgman'

redback.addStructure(
	'BetterRateLimit'
	
	init: (options = {}) ->
	
		@bucket_count = options.bucket_count ? 10
		@bucket_time = options.bucket_time ? 60 * 10
		@bucket_interval = Math.round @bucket_time / @bucket_count
	
	getBucket: (time) ->
	
		time = (time ? new Date().getTime()) / 1000
		Math.floor (time % @bucket_time) / @bucket_interval
		
	add: (subject) ->
	
		multi = @client.multi()
		execute = Promise.promisify multi.exec, multi

		subject = @key + ':' + subject + ':' + @getBucket()
		
		multi.incr subject
		multi.expire subject, @bucket_time
		
		execute()
		
	count: (subject) ->
	
		multi = @client.multi()
		execute = Promise.promisify multi.exec, multi

		bucket = @getBucket()
		count = @bucket_count
		subject = @key + ':' + subject

		multi.get subject + ':' + bucket
		while --count
			multi.get subject + ':' + (--bucket + @bucket_count) % @bucket_count
	
		execute().then (counts) ->
			
			counts.reduce(
				(l, r) ->
					return l unless r?
					return r unless l?
					
					(parseInt l, 10) + (parseInt r, 10)
				0
			)
				
)

exports.Limiter = class Limiter
	
	constructor: (root, @threshold, options = {}) ->
		
		unless @threshold instanceof ThresholdTime
			throw new TypeError(
				"Limiter(#{root}) must be constructed with a valid threshold!"
			)
			
		options.bucket_time ?= @threshold.calculateSeconds()
			
		@limiter = redback.createBetterRateLimit root, options
	
	add: (keys) -> Promise.all(@limiter.add key for key in keys)
	
	addAndCheckThreshold: (keys) -> @add(keys).then => @checkThreshold keys
	
	count: (keys) ->
		
		Promise.all(@limiter.count key for key in keys).then(

			(counts) -> counts.reduce(
				(l, r) -> if l > r then l else r
				-Infinity
			)
		)

	checkThreshold: (keys) ->
		@count(keys).then (count) => count > @threshold.count()
		
exports.threshold = (count) -> new Threshold count
				
class Threshold
	
	constructor: (@_count) ->
	
	every: (amount) -> new ThresholdTime @_count, amount
	
class ThresholdTime
	
	constructor: (@_count, @_amount) ->
		
		@_multiplier = 1
	
	calculateSeconds: -> @_amount * @_multiplier
	
	count: -> @_count
	
	multipliers =
		milliseconds: 1 / 1000
		seconds: 1
		minutes: 60
	
	backwardMultipliers = {}
	
	for key, multiplier of multipliers
		backwardMultipliers[multiplier] = key
		 			
		do (key, multiplier) =>
			@::[key] = ->
				@_multiplier = multiplier
				this

	time: -> "#{@_amount} #{backwardMultipliers[@_multiplier]}"
