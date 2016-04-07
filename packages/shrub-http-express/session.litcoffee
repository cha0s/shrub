# Express - routes

    CookieParser = require 'cookie-parser'
    ExpressSession = require 'express-session'

    express = null

    config = require 'config'
    {Middleware} = require 'middleware'

    cookieParser = null
    sessionStore = null
    signature = null

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubCoreBootstrapMiddleware`.

      registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

        label: 'Bootstrap session handling'
        middleware: [

          (next) ->

            express = require 'express'
            signature = require 'cookie-signature'

            {cookie} = config.get(
              'packageSettings:shrub-session'
            )

            cookieParser = CookieParser cookie.cryptoKey

            OrmStore = require('shrub-session/store') express
            sessionStore = new OrmStore()

            next()

        ]

#### Implements hook `shrubHttpMiddleware`.

Parse cookies and load any session.

      registrar.registerHook 'shrubHttpMiddleware', (http) ->

        label: 'Load session from cookie'
        middleware: sessionMiddleware()

#### Implements hook `shrubRpcRoutesAlter`.

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

#### Implements hook `shrubSocketConnectionMiddleware`.

      registrar.registerHook 'shrubSocketConnectionMiddleware', ->

        label: 'Load session from cookie'
        middleware: sessionMiddleware()

    sessionMiddleware = ->

      {cookie, key} = config.get 'packageSettings:shrub-session'

      return [

Express cookie parser.

        cookieParser

Session reification.

        ExpressSession(
          cookie: cookie
          key: key
          resave: false
          saveUninitialized: false
          secret: cookie.cryptoKey
          store: sessionStore
        )

If this is the first request made by a client, the cookie won't exist in
req.headers.cookie. We normalize that inconsistency, so all consumers of the
cookie will have a consistent interface on the first as well as subsequent
requests.

        (req, res, next) ->

If the client is already in sync, awesome!

          return next() if req.signedCookies[key] is req.sessionID

Generate the cookie

          val = 's:' + signature.sign req.sessionID, cookie.cryptoKey
          cookieText = req.session.cookie.serialize key, val

Commit the session before offering the cookie, otherwise it wouldn't actually
be pointing at anything yet.

          req.session.save (error) ->
            next error if error?

            req.signedCookies[key] = req.sessionID
            req.headers.cookie = cookieText
            next()

      ]
