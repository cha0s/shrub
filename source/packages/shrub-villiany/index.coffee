# Villiany

*Watch for and punish bad behavior.*

```coffeescript
i8n = null
Promise = null

config = require 'config'

orm = null

{AuthorizationFailure} = require 'shrub-socket/manager'

Fingerprint = require 'fingerprint'
logger = null
villianyLimiter = null

exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubCorePreBootstrap`](../../hooks#shrubcoreprebootstrap)

```coffeescript
  registrar.registerHook 'shrubCorePreBootstrap', ->

    i8n = require 'inflection'
    Promise = require 'bluebird'

    logging = require 'logging'

    orm = require 'shrub-orm'

    logger = logging.create 'logs/villiany.log'

    {Limiter} = require 'shrub-limiter'

    {
      thresholdScore
      thresholdMs
    } = config.get 'packageConfig:shrub-villiany:ban'

    villianyLimiter = new Limiter(
      'villiany'
      Limiter.threshold(thresholdScore).every(thresholdMs).milliseconds()
    )
```

#### Implements hook [`shrubOrmCollections`](../../hooks#shrubormcollections)

```coffeescript
  registrar.registerHook 'shrubOrmCollections', ->

    Fingerprint = require 'fingerprint'
```

Bans.

```coffeescript
    Ban = attributes: expires: 'dateTime'
```

The structure of a ban is dictated by the fingerprint structure.

```coffeescript
    Fingerprint.keys().forEach (key) ->
      Ban.attributes[key] =
        index: true
        type: 'string'
```

Generate a test for whether each fingerprint key has been banned. e.g.
`session` -> `isSessionBanned`

```coffeescript
      Ban[i8n.camelize "is_#{key}_banned", true] = (value) ->
        method = i8n.camelize "find_by_#{key}", true
        Promise.cast(this[method] value).bind({}).then((@bans) ->
          return false if @bans.length is 0
```

Destroy all expired bans.

```coffeescript
          expired = @bans.filter (ban) ->
            ban.expires.getTime() <= Date.now()
          Promise.all expired.map (ban) -> ban.destroy()

        ).then (expired) ->

          _ = require 'lodash'
```

More bans than those that expired?

```coffeescript
          isBanned: @bans.length > expired.length
```

Ban ttl.

```coffeescript
          ttl: Math.round (_.difference(@bans, expired).reduce(
            (l, r) ->

              if l > r.expires.getTime()
                l
              else
                r.expires.getTime()

            -Infinity
```

It's a timestamp, and it's in ms.

```coffeescript
          ) - Date.now()) / 1000
```

Create a ban from a fingerprint.

```coffeescript
    Ban.createFromFingerprint = (fingerprint, expires) ->

      unless expires?
        settings = config.get 'packageConfig:shrub-villiany:ban'
        expires = parseInt settings.thresholdMs

      data = expires: new Date Date.now() + expires
      data[key] = value for key, value of fingerprint
      @create data

    'shrub-ban': Ban
```

#### Implements hook [`shrubHttpMiddleware`](../../hooks#shrubhttpmiddleware)

```coffeescript
  registrar.registerHook 'shrubHttpMiddleware', ->

    label: 'Provide villiany management'
    middleware: [

      (req, res, next) ->

        req.on 'shrubVillianyKick', (subject, ttl) ->

          res.status 401
          res.end buildBanMessage subject, ttl

        next()

      enforcementMiddleware

    ]
```

#### Implements hook [`shrubConfigServer`](../../hooks#shrubconfigserver)

```coffeescript
  registrar.registerHook 'shrubConfigServer', ->

    ban:
```

Villiany threshold score.

```coffeescript
      thresholdScore: 1000
```

10 minute villiany threshold window by default.

```coffeescript
      thresholdMs: 1000 * 60 * 10
```

#### Implements hook [`shrubSocketConnectionMiddleware`](../../hooks#shrubsocketconnectionmiddleware)

```coffeescript
  registrar.registerHook 'shrubSocketConnectionMiddleware', ->

    label: 'Provide villiany management'
    middleware: socketMiddleware()
```

#### Implements hook [`shrubRpcRoutesAlter`](../../hooks#shrubrpcroutesalter)

```coffeescript
  registrar.registerHook 'shrubRpcRoutesAlter', (routes) ->

    {spliceRouteMiddleware} = require 'shrub-rpc'

    for path, route of routes
      spliceRouteMiddleware route, 'shrub-villiany', socketMiddleware()

    return
```

#### Implements hook [`shrubVillianyReport`](../../hooks#shrubvillianyreport)

Catch villiany reports.

```coffeescript
  registrar.registerHook 'shrubVillianyReport', (req, score, type, excluded = []) ->

    Ban = orm.collection 'shrub-ban'
```

Terminate the chain if not a villian.

```coffeescript
    class NotAVillian extends Error
      constructor: (@message) ->

    fingerprint = new Fingerprint req
    inlineKeys = fingerprint.inlineKeys excluded

    villianyLimiter.accrueAndCheckThreshold(
      inlineKeys, score

    ).then((isVillian) ->
```

Log this transgression.

```coffeescript
      fingerprint = fingerprint.get excluded

      message = "Logged villiany score #{
        score
      } for #{
        type
      }, fingerprint: #{
        JSON.stringify fingerprint
      }"
      message += ', which resulted in a ban.' if isVillian
      logger[if isVillian then 'error' else 'warn'] message

      throw new NotAVillian unless isVillian
```

Ban.

```coffeescript
      Ban.createFromFingerprint fingerprint

    ).then(->
```

Kick.

```coffeescript
      req.emit 'shrubVillianyKick', villianyLimiter.ttl inlineKeys

    ).then(-> true).catch NotAVillian, -> false
```

Enforce bans.

```coffeescript
enforcementMiddleware = (req, res, next) ->

  Ban = orm.collection 'shrub-ban'
```

Terminate the request if a ban is enforced.

```coffeescript
  class RequestBanned extends Error
    constructor: (@message, @key, @ttl) ->

  fingerprint = new Fingerprint req
  banPromises = for key, value of fingerprint.get()
    do (key, value) ->
      method = i8n.camelize "is_#{key}_banned", true
      Ban[method](value).then ({isBanned, ttl}) ->
        throw new RequestBanned '', key, ttl if isBanned

  Promise.all(banPromises).then(-> next()).catch(
```

RequestBanned error just means we should emit.

```coffeescript
    RequestBanned, ({key, ttl}) -> req.emit 'shrubVillianyKick', key, ttl
  ).catch (error) -> next error
```

Build a nice message for the villian.

```coffeescript
buildBanMessage = (subject, ttl) ->

  moment = require 'moment'

  message = if subject?
    "Your #{subject} is banned."
  else
    'You are banned.'

  message += " The ban will be lifted #{
    moment().add(ttl, 'seconds').fromNow()
  }." if ttl?

  message
```

Middleware for sockets.

```coffeescript
socketMiddleware = -> [

  (req, res, next) ->

    req.on 'shrubVillianyKick', (subject, ttl) ->

      throw new AuthorizationFailure unless req.socket?

      req.socket.emit 'core.reload'

    next()

  enforcementMiddleware

]
```
