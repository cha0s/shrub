
Promise = require 'bluebird'
redis = require 'connect-redis/node_modules/redis'
redback = require('redback').use redis.createClient()

pkgman = require 'pkgman'

redback.addStructure(
	'BetterRateLimit'
	
	init: (options = {}) ->
	
		@bucketTime = options.bucketTime ? 60 * 10
	
	add: (subject, increment = 1) ->
	
		exists = Promise.promisify @client.exists, @client
		rpushx = Promise.promisify @client.rpushx, @client
		
		subject = @key + ':' + subject
		
		exists(subject).bind(this).then (exists) ->
			
			if exists
				
				rpushx subject, increment
			
			else
		
				multi = @client.multi()
				multi.rpush subject, increment
				multi.expire subject, @bucketTime
				
				Promise.promisify(multi.exec, multi)()
				
	count: (subject) ->
	
		lrange = Promise.promisify @client.lrange, @client
		lrange(@key + ':' + subject, 0, -1).then (counts) ->
			
			counts.reduce(
				(l, r) ->
					return l unless r?
					return r unless l?
					
					parseInt(l, 10) + parseInt(r, 10)
				0
			)
		
	ttl: (subject) ->
				
		Promise.promisify(@client.ttl, @client) @key + ':' + subject
		
)

exports.Limiter = class Limiter
	
	constructor: (root, @threshold, options = {}) ->
		
		unless @threshold instanceof ThresholdTime
			throw new TypeError(
				"Limiter(#{root}) must be constructed with a valid threshold!"
			)
			
		options.bucketTime ?= @threshold.calculateSeconds()
			
		@limiter = redback.createBetterRateLimit root, options
	
	add: (keys, increment = 1) ->
		
		Promise.all(@limiter.add key, increment for key in keys)
	
	addAndCheckThreshold: (keys, increment = 1) ->
		
		@add(keys, increment).then => @checkThreshold keys
	
	_reduction: (keys, index) ->
	
		Promise.all(@limiter[index] key for key in keys).then(

			(reduction) -> reduction.reduce(
				(l, r) -> if l > r then l else r
				-Infinity
			)
		)

	count: (keys) -> @_reduction keys, 'count'
		
	ttl: (keys) -> @_reduction keys, 'ttl'
		
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
	
	for key, multiplier of multipliers
		do (key, multiplier) =>
			@::[key] = ->
				@_multiplier = multiplier
				this
