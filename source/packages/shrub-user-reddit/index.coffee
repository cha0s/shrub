reddit user authentication.

```coffeescript
```

*Authorize using a reddit account.*

```coffeescript
config = require 'config'
errors = require 'errors'

orm = null
passport = null
Promise = null

clientModule = require './client'
```

*ORM collection and passport strategy for local authentication.*

```coffeescript
exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubConfigServer`](../../../hooks#shrubconfigserver)

```coffeescript
  registrar.registerHook 'shrubConfigServer', ->

    siteHostname = config.get 'packageConfig:shrub-core:siteHostname'
```

See: [passport-reddit](https://github.com/Slotos/passport-reddit) for
more information about which configuration options are available.

```coffeescript
    constructionOptions:
```

The path that the client gets sent back to from reddit authorization.

```coffeescript
      callbackURL: "http://#{siteHostname}/user/reddit/auth/callback"
```

Public client ID.

```coffeescript
      clientID: 'REDDIT_CLIENT_ID'
```

Client secret.

```coffeescript
      clientSecret: 'REDDIT_CLIENT_SECRET'
```

Adjust scope configuration (by default, identity is provided).

```coffeescript
      scope: []

    authorizationOptions:
```

How long the authorization should persist.

```coffeescript
      duration: 'temporary'
```

#### Implements hook [`shrubCorePreBootstrap`](../../../hooks#shrubcoreprebootstrap)

```coffeescript
  registrar.registerHook 'shrubCorePreBootstrap', ->

    orm = require 'shrub-orm'
    passport = require 'passport'
    Promise = require 'bluebird'
```

#### Implements hook [`shrubUserLoginStrategies`](../../../hooks#shrubuserloginstrategies)

```coffeescript
  registrar.registerHook 'shrubUserLoginStrategies', ->
    strategy = clientModule.shrubUserLoginStrategies()

    RedditStrategy = require('passport-reddit').Strategy
    UserReddit = orm.collection 'shrub-user-reddit'
```

Implement a reddit passport strategy.

```coffeescript
    options = config.get(
      'packageConfig:shrub-user-reddit:constructionOptions'
    )
    options.passReqToCallback = true
```

Verification callback: find or create a reddit user instance and pass
it along.

```coffeescript
    verifyCallback = (req, accessToken, refreshToken, profile, done) ->

      UserReddit.findOrCreate(

        redditId: profile.id
      ,
        redditId: profile.id
        name: profile.name
        accessToken: accessToken
        refreshToken: refreshToken

      ).then((instance) ->

        instance.model = 'shrub-user-reddit'
        return instance

      ).nodeify done
```

Implement a [reddit Passport](https://github.com/Slotos/passport-reddit)
login strategy.

```coffeescript
    passportStrategy = new RedditStrategy options, verifyCallback
    passportStrategy.name = 'shrub-user-reddit'
    strategy.passportStrategy = passportStrategy

    return strategy
```

#### Implements hook [`shrubHttpRoutes`](../../../hooks#shrubhttproutes)

```coffeescript
  registrar.registerHook 'shrubHttpRoutes', (http) ->
    routes = []

    crypto = require 'server/crypto'
```

Provide the reddit authorization entry point.

```coffeescript
    routes.push
      path: '/user/reddit/auth'
      receiver: (req, res, next) ->
```

Generate a random string to send as the 'state' token, so we can
verify we were the source of this authentication request.

```coffeescript
        crypto.randomBytes(32).then (bytes) ->

          options = config.get(
            'packageConfig:shrub-user-reddit:authorizationOptions'
          )
          options.state = req.session.state = bytes.toString 'hex'

          req.authorize(
            'shrub-user-reddit', options, res
          ).nodeify next
```

Provide the reddit authorization callback.

```coffeescript
    routes.push
      path: '/user/reddit/auth/callback'
      receiver: (req, res, next) ->

        if req.query.state isnt req.session.state
          error = new Error(
            "Your reddit session state didn't match on the callback"
          )
          error.code = 403
          return next error

        promise = req.authorize(
          'shrub-user-reddit', res
        )

        require('shrub-user/login').loginWithInstance(
          promise, req
        ).then(-> next()).catch (error) ->
```

In case of an authorization error, we want to send it to the
client; it's not a server error.

```coffeescript
          (req.session.errorMessages ?= []).push errors.serialize error
          return res.redirect '/'

    return routes
```

#### Implements hook [`shrubUserRedactors`](../../../hooks#shrubuserredactors)

```coffeescript
  registrar.registerHook 'shrubUserRedactors', ->

    'shrub-user-reddit': [

      (object, user) ->

        redacted = name: object.name
        return redacted

    ]
```

#### Implements hook [`shrubOrmCollections`](../../../hooks#shrubormcollections)

```coffeescript
  registrar.registerHook 'shrubOrmCollections', ->

    crypto = require 'server/crypto'
```

Invoke the client hook implementation.

```coffeescript
    collections = clientModule.shrubOrmCollections()

    {
      'shrub-user-reddit': UserReddit
    } = collections
```

## UserReddit#associatedUser

###### TODO: This should be in a superclass.

*Get the user (if any) associated with this instance.*

```coffeescript
    UserReddit.attributes.associatedUser = ->
      {
        'shrub-user-instance': UserInstance
        'shrub-user': User
      } = orm.collections()

      UserInstance.findOne(
        model: 'shrub-user-reddit'
        modelId: @id
      ).then (userInstance) -> User.findOnePopulated id: userInstance?.user

    collections
```
