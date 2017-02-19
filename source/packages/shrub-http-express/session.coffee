# Express - routes

```coffeescript
CookieParser = require 'cookie-parser'
ExpressSession = require 'express-session'

express = null

config = require 'config'
{Middleware} = require 'middleware'

cookieParser = null
sessionStore = null
signature = null

exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubCoreBootstrapMiddleware`](../../hooks#shrubcorebootstrapmiddleware)

```coffeescript
  registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

    label: 'Bootstrap session handling'
    middleware: [

      (next) ->

        express = require 'express'
        signature = require 'cookie-signature'

        {cookie} = config.get(
          'packageConfig:shrub-session'
        )

        cookieParser = CookieParser cookie.cryptoKey

        OrmStore = require('shrub-session/store') express
        sessionStore = new OrmStore()

        next()

    ]
```

#### Implements hook [`shrubHttpMiddleware`](../../hooks#shrubhttpmiddleware)

Parse cookies and load any session.

```coffeescript
  registrar.registerHook 'shrubHttpMiddleware', (http) ->

    label: 'Load session from cookie'
    middleware: sessionMiddleware()
```

#### Implements hook [`shrubRpcRoutesAlter`](../../hooks#shrubrpcroutesalter)

```coffeescript
  registrar.registerHook 'shrubRpcRoutesAlter', (routes) ->

    {spliceRouteMiddleware} = require 'shrub-rpc'

    loadSessionMiddleware = (req, res, next) ->

      req.loadSession = (done) ->

        sessionMiddleware_ = new Middleware()
        for fn in sessionMiddleware()
          sessionMiddleware_.use fn

        sessionMiddleware_.dispatch req, res, (error) ->
          return next error if error?
          done()

      next()

    loadSessionMiddleware.weight = -5000

    for path, route of routes
      route.middleware.unshift loadSessionMiddleware
      spliceRouteMiddleware(
        route, 'shrub-http-express/session', sessionMiddleware()
      )

    return
```

#### Implements hook [`shrubSocketConnectionMiddleware`](../../hooks#shrubsocketconnectionmiddleware)

```coffeescript
  registrar.registerHook 'shrubSocketConnectionMiddleware', ->

    label: 'Load session from cookie'
    middleware: sessionMiddleware()

sessionMiddleware = ->

  {cookie, key} = config.get 'packageConfig:shrub-session'

  return [
```

Express cookie parser.

```coffeescript
    cookieParser
```

Session reification.

```coffeescript
    ExpressSession(
      cookie: cookie
      key: key
      resave: false
      saveUninitialized: true
      secret: cookie.cryptoKey
      store: sessionStore
    )

  ]
```
