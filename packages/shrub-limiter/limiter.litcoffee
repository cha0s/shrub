# Limiter

*ORM-backed limit handling. Accrue and check scores, and check Time-to-live
across multiple [fingerprint keys](source/packages/shrub-audit/fingerprint).*

    Promise = null

    orm = null

## Limiter

Provides methods to tally scores, and compare them against a threshold of
time.

The [limiter](source/packages/shrub-limiter) package implements hook
[`shrubRpcRoutesAlter`](hooks/#shrubrpcroutesalter) to allow RPC routes to
limit consumers to a specified number of requests per time period. For
instance, by default the [user login](source/packages/user/login) route limits
the number of logins a user may attempt to 3 every 30 seconds.

    module.exports = class Limiter

## Limiter.threshold

Expose a factory method for constructing Threshold instances. A Threshold is
defined like:

```
var Limiter = require('shrub-limiter').Limiter;
Limiter.threshold(4).every(20).minutes();
```

Which means that the threshold represents the allowance of a score of 4 to
accumulate over the period of 20 minutes. If more score is accrued during that
window, then the threshold is said to be crossed.

      @threshold: (score) -> new ThresholdBase score

## *constructor*

* (string) `key` - A unique key for this limiter, e.g.
  "rpc://user.login:limiter"
* (Threshold) `threshold` - A threshold, see below for details.

*Create a limiter.*

      constructor: (key, @threshold, @excluded = []) ->

Ensure it's a threshold.

        throw new TypeError(
          "Limiter(#{key}) must be constructed with a valid threshold!"
        ) unless @threshold instanceof ThresholdFinal

        Promise ?= require 'bluebird'

        orm ?= require 'shrub-orm'

Create the low-level limiter.

        @limiter = new LimiterManager key, @threshold.calculateSeconds()

## Limiter#add

* (array) `keys` - An array of keys, e.g. a flattened array of keys from
  [`Fingerprint.inlineKeys`](source/packages/shrub-audit/fingerprint#fingerprintinlinekeys)
* (Number) `score` - The score to add. Defaults to 1.

*Accrue score for a limiter.*

      accrue: (keys, score = 1) ->
        Promise.all (@limiter.accrue key, score for key in keys)

## Limiter#accrueAndCheckThreshold

* (array) `keys` - An array of keys, e.g. a flattened array of keys from
  [`Fingerprint.inlineKeys`](source/packages/shrub-audit/fingerprint#fingerprintinlinekeys)
* (integer) `score` - The score to add. Defaults to 1.

*Add score to a limiter, and check it against the threshold.*

      accrueAndCheckThreshold: (keys, score = 1) ->
        @accrue(keys, score).then => @checkThreshold keys

## Limiter#score

* (array) `keys` - An array of keys, e.g. a flattened array of keys from
  [`Fingerprint.inlineKeys`](source/packages/shrub-audit/fingerprint#fingerprintinlinekeys)

*Check score for a limiter.*

      score: (keys) -> @_largest keys, 'score'

## Limiter#ttl

* (array) `keys` - An array of keys, e.g. a flattened array of keys from
  [`Fingerprint.inlineKeys`](source/packages/shrub-audit/fingerprint#fingerprintinlinekeys)

*Time-to-live for a limiter.*

      ttl: (keys) -> @_largest keys, 'ttl'

## Limiter#checkThreshold

* (array) `keys` - An array of keys, e.g. a flattened array of keys from
  [`Fingerprint.inlineKeys`](source/packages/shrub-audit/fingerprint#fingerprintinlinekeys)

*Check the current limiter score against the threshold.*

      checkThreshold: (keys) ->
        @score(keys).then (score) => score > @threshold.score()

## Limiter#_largest

*Find the largest result from a group of results.*

      _largest: (keys, index) ->
        Promise.all(
          @limiter[index] key for key in keys

        ).then (reduction) ->
          reduction.reduce ((l, r) -> if l > r then l else r), -Infinity

    class LimiterManager

## *constructor*

* (string) `key` - A unique key for this limiter, e.g.
  "rpc://user.login:limiter"
* (Threshold) `threshold` - A threshold, see below for details.

*...*

      constructor: (@key, @threshold) ->

## LimiterManager#add

* (string) `id` - The ID of the limiter.
* (Number) `score` - The score to add. Defaults to 1.

*Add score to a limiter.*

      accrue: (id, score = 1) ->
        key = "#{@key}:#{id}"

        Limit = orm.collection 'shrub-limit'
        Limit.findOrCreate(
          key: key
        ,
          key: key
        ).populateAll().then((limit) =>

Reset if it's expired.

          limit.reset() if 0 >= limit.ttl @threshold

          return limit

        ).then (limit) -> limit.accrue(parseInt score).save()

## LimiterManager#score

* (string) `id` - The ID of the limiter.

*Check score for a limiter.*

      score: (id) ->

Get all scores for this limiter.

        Limit = orm.collection 'shrub-limit'
        Limit.findOne(key: "#{@key}:#{id}").populateAll().then (limit) =>
          return 0 unless limit?
          return limit.score() if 0 < limit.ttl @threshold

Reset if it's expired.

          limit.reset().save().then -> 0

## LimiterManager#ttl

* (string) `id` - The ID of the limiter.

*Time-to-live for a limiter.*

      ttl: (id) ->

        Limit = orm.collection 'shrub-limit'
        Limit.findOne(key: "#{@key}:#{id}").then (limit) =>
          return 0 unless limit?
          return ttl if 0 < ttl = limit.ttl @threshold

Reset if it's expired.

          limit.reset().save().then -> 0

## ThresholdBase

*The base class used to define a threshold.*

    class ThresholdBase

## *constructor*

* (Number) `score` - The maximum score allowed to accrue.

*Create a threshold base object.*

      constructor: (@_score) ->

## ThresholdBase#every

* (Number) `amount` - The quantity of time units this threshold concerns e.g,
  if the threshold is every 5 minutes, this will be `5`.

*Define the quantity of time this threshold concerns.*

      every: (amount) -> new ThresholdMultiplier @_score, amount

## ThresholdMultiplier

*A threshold class to collect the multiplier.*

    class ThresholdMultiplier

## *constructor*

* (Number) `score` - Passed along from ThresholdBase.
* (Number) `amount` - Passed along from ThresholdBase.

*Create a threshold.*

      constructor: (@_score, @_amount) ->

        @_multiplier = 1

## ThresholdMultiplier#milliseconds
## ThresholdMultiplier#seconds
## ThresholdMultiplier#minutes

*Add a method for each multipler. This is this way just to DRY things up.*

      multipliers =
        milliseconds: 1 / 1000
        seconds: 1
        minutes: 60

      for key, multiplier of multipliers
        do (key, multiplier) ->
          ThresholdMultiplier::[key] = ->
            @_multiplier = multiplier

Return a finalized threshold.

            new ThresholdFinal @_score, @_amount, @_multiplier

## ThresholdFinal

A finalized threshold definition.

    class ThresholdFinal

## *constructor*

* (Number) `score` - Passed along from ThresholdMultiplier.
* (Number) `amount` - Passed along from ThresholdMultiplier.
* (Number) `multiplier` - Passed along from ThresholdMultiplier.

*Create a threshold.*

      constructor: (score, amount, multiplier) ->

        @calculateSeconds = -> amount * multiplier
        @score = -> score
