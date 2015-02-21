# Rate limiter

*Limits the rate at which clients can do certain operations, like call RPC
endpoints.*

    exports.SKIP = SKIP = {}

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `collections`.

      registrar.registerHook 'collections', ->

        _ = require 'lodash'

        Limit =

          attributes:

## Limit#key

*The limiter key.*

            key:
              type: 'string'
              index: true

## Limit#scores

*Scores accrued for this limit.*

            scores:
              collection: 'shrub-limit-score'
              via: 'limit'

## Limit#accrue

* (Number) `score` - The numeric score to accrue.

*Accrue a score for this limit.*

            accrue: (score) ->
              @scores.add score: score

              return this

## Limit#passed

* (Number) `threshold` - The threshold duration in seconds.

*Check whether a limit has passed the time threshold.*

            passed: (threshold) -> 0 >= @ttl threshold

## Limit#reset

*Reset scores and created time.*

            reset: ->
              @scores.remove id for id in _.pluck @scores, 'id'
              @createdAt = new Date()

              return this

## Limit#reset

*Get the sum of all scores for this limit.*

            score: ->
              _.pluck(@scores, 'score').reduce ((l, r) -> l + r), 0

## Limit#ttl

* (Number) `threshold` - The threshold duration in seconds.

*Get the current time-to-live for this limit.*

            ttl: (threshold) ->
              diff = (Date.now() - @createdAt.getTime()) / 1000
              Math.ceil threshold - diff

        LimitScore =

          attributes:

            score: 'integer'

            limit: model: 'shrub-limit'

        'shrub-limit': Limit
        'shrub-limit-score': LimitScore

#### Implements hook `endpointAlter`.

Allow RPC endpoint definitions to specify rate limiters.

      registrar.registerHook 'endpointAlter', (endpoints) ->

        moment = require 'moment'

        errors = require 'errors'
        pkgman = require 'pkgman'

A limiter on a route is defined like:

* `message`: The message returned to the client when the threshold is
  passed.
* `threshold`: The [threshold](./limiter#threshold) for this limiter.
* `ignoreKeys`: The
  [fingerprint keys](source/packages/shrub-audit/fingerprint) to ignore when
  determining the total limit. In this example, the IP address and session ID
  would be ignored.

        Object.keys(endpoints).forEach (route) ->
          endpoint = endpoints[route]

No limiter? Nevermind...

          return unless endpoint.limiter?

Create a limiter based on the threshold defined.

          endpoint.limiter.instance = new Limiter(
            "rpc://#{route}", endpoint.limiter.threshold
          )

Set defaults.

          endpoint.limiter.excludedKeys ?= []
          endpoint.limiter.message ?= 'You are doing that too much.'
          endpoint.limiter.villianyScore ?= 20

Add a validator, where we'll check the threshold.

          endpoint.validators.push (req, res, next) ->

            {
              excludedKeys
              instance
              message
              villianyScore
            } = endpoint.limiter

Allow packages to check and optionally skip the limiter.

            for rule in pkgman.invokeFlat 'limiterCheck', req
              continue unless rule?
              return next() if SKIP is rule

            inlineKeys = req.fingerprint.inlineKeys excludedKeys

Build a nice error message for the client, so they hopefully will stop doing
that.

            sendLimiterError = ->
              instance.ttl(inlineKeys).then (ttl) ->
                next errors.instantiate(
                  'limiterThreshold'
                  message
                  moment().add('seconds', ttl).fromNow()
                )

Accrue a hit and check the threshold.

            instance.accrueAndCheckThreshold(inlineKeys).then((isLimited) ->
              return next() unless isLimited

Zero score skips the villiany check.

              return sendLimiterError() if villianyScore is 0
              unless pkgman.packageExists 'shrub-villiany'
                return sendLimiterError()

              req.reportVilliany(
                villianyScore
                "rpc://#{req.route}:limiter"
                excludedKeys

              ).then (isVillian) ->
                return next() if isVillian

                sendLimiterError()

            ).catch next

#### Implements hook `transmittableError`.

Just defer to client, where the error is defined.

      registrar.registerHook 'transmittableError', require('./client').transmittableError

    exports.Limiter = Limiter = require './limiter'
