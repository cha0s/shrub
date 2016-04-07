# Rate limiter

*Limits the rate at which clients can do certain operations, like call RPC
routes.*

    pkgman = require 'pkgman'

    exports.SKIP = SKIP = {}

A limiter on a route is defined like:

```javascript

registrar.registerHook('shrubRpcRoutes', function() {

  var shrubLimiter = require 'shrub-limiter'
  var Limiter = shrubLimiter.Limiter;
  var LimiterMiddleware = shrubLimiter.LimiterMiddleware;

  var routes = []

  routes.push({

.    path: 'my-package/route',

.    middleware: [

.      ...

.      'shrub-villiany' // Include if limit infractions lead to eventual ban

.      new LimiterMiddleware(
.        limiterDefinitionObject
.      )

.      ...

.    ]

  });

  return routes;
});

```

<small>***NOTE:*** *Ignore the leading dots, they are a result of literate coffee
limitations.*</small>

Where `limiterDefinitionObject` above is defined as an object with the
following properties:

* `threshold`: The [threshold](./limiter#threshold) for this limiter.
* `message`: The message returned to the client when the threshold is
  passed.
* `ignoreKeys`: The
  [fingerprint keys](source/server/fingerprint) to ignore when
  determining the total limit.
* `villianyScore`: The score accumulated when this limit is crossed.

### LimiterMiddleware

    exports.LimiterMiddleware = class LimiterMiddleware

      constructor: (@config) ->

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubOrmCollections`.

      registrar.registerHook 'shrubOrmCollections', ->

        _ = require 'lodash'

        Limit =

          autoPK: false

          associations: [
            alias: 'scores'
          ]

          attributes:

## Limit#key

*The limiter key.*

            key:
              type: 'string'
              primaryKey: true

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
              @scores.remove id for id in _.map @scores, 'id'
              @createdAt = new Date()

              return this

## Limit#reset

*Get the sum of all scores for this limit.*

            score: ->
              _.map(@scores, 'score').reduce ((l, r) -> l + r), 0

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

#### Implements hook `shrubRpcRoutesAlter`.

Allow RPC routes definitions to specify rate limiters.

      registrar.registerHook 'shrubRpcRoutesAlter', (routes) ->

        Promise = require 'bluebird'
        moment = require 'moment'

        errors = require 'errors'

Check all routes' middleware for limiter definitions.

        Object.keys(routes).forEach (path) ->
          route = routes[path]

          Fingerprint = require 'fingerprint'

          for fn, index in route.middleware
            continue unless fn instanceof exports.LimiterMiddleware

            route.limiter = fn.config

Create a limiter based on the threshold defined.

            route.limiter.instance = new Limiter(
              "rpc://#{path}", route.limiter.threshold
            )

Set defaults.

            route.limiter.excludedKeys ?= []
            route.limiter.message ?= 'You are doing that too much.'
            route.limiter.villianyScore ?= 20

Add a validator, where we'll check the threshold.

            route.middleware[index] = (req, res, next) ->

              {
                excludedKeys
                instance
                message
                villianyScore
              } = route.limiter

Allow packages to check and optionally skip the limiter.

#### Invoke hook `shrubLimiterCheck`.

              for rule in pkgman.invokeFlat 'shrubLimiterCheck', req
                continue unless rule?
                return next() if SKIP is rule

              fingerprint = new Fingerprint req

              inlineKeys = fingerprint.inlineKeys excludedKeys

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

#### Invoke hook `shrubVillianyReport`.

                Promise.all(
                  pkgman.invokeFlat(
                    'shrubVillianyReport'
                    req
                    villianyScore
                    "rpc://#{path}:limiter"
                    excludedKeys
                  )

                ).then (reports) ->

Only send an error if the user wasn't banned for this.

                  if reports.filter((isBanned) -> !!isBanned).length is 0
                    sendLimiterError()

              ).catch next

#### Implements hook `shrubTransmittableErrors`.

Just defer to client, where the error is defined.

      registrar.registerHook 'shrubTransmittableErrors', require('./client').shrubTransmittableErrors

    exports.Limiter = Limiter = require './limiter'
