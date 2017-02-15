# Passport integration
```coffeescript
```
*Authentication system, leaning on [passport](http://passportjs.org).*
```coffeescript
middleware = require 'middleware'
pkgman = require 'pkgman'

orm = null
passport = null
Promise = null

beforeLoginMiddleware = null
afterLoginMiddleware = null
beforeLogoutMiddleware = null
afterLogoutMiddleware = null

exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubCorePreBootstrap`.
```coffeescript
  registrar.registerHook 'shrubCorePreBootstrap', ->

    orm = require 'shrub-orm'
    passport = require 'passport'
    Promise = require 'bluebird'
```
#### Implements hook `shrubCoreBootstrapMiddleware`.
```coffeescript
  registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

    Promise = require 'bluebird'

    label: 'Bootstrap user authorization'
    middleware: [

      (next) ->

        {IncomingMessage} = require 'http'
```
## IncomingMessage::authorize

* (string) `method` - The authorization method.

* (response) `res` - The HTTP/socket response object.

*Authorize a user instance.*
```coffeescript
        IncomingMessage::authorize = (method, res) ->
          self = this

          new Promise (resolve, reject) ->

            self._passport.instance.authenticate(
              method
              (error, user, info) ->
                return reject error if error?
                resolve user, info

            ) self, res
```
#### Invoke hook `shrubUserBeforeLoginMiddleware`.
```coffeescript
        beforeLoginMiddleware = middleware.fromConfig(
          'shrub-user:beforeLoginMiddleware'
        )
```
#### Invoke hook `shrubUserAfterLoginMiddleware`.
```coffeescript
        afterLoginMiddleware = middleware.fromConfig(
          'shrub-user:afterLoginMiddleware'
        )
```
#### Invoke hook `shrubUserBeforeLogoutMiddleware`.
```coffeescript
        beforeLogoutMiddleware = middleware.fromConfig(
          'shrub-user:beforeLogoutMiddleware'
        )
```
#### Invoke hook `shrubUserAfterLogoutMiddleware`.
```coffeescript
        afterLogoutMiddleware = middleware.fromConfig(
          'shrub-user:afterLogoutMiddleware'
        )
```
#### Invoke hook `shrubUserLoginStrategies`.

Use passport authorization strategies.
```coffeescript
        for packageName, strategy of pkgman.invoke 'shrubUserLoginStrategies'
          passport.use strategy.passportStrategy
```
Passport serialization callback. Store the user ID.
```coffeescript
        passport.serializeUser (user, done) -> done null, user.id
```
Passport deserialization callback.
```coffeescript
        passport.deserializeUser (req, id, done) ->
```
Load user based on ID
```coffeescript
          promise = orm.collection(
            'shrub-user'
          ).findOnePopulated(
            id: id
          ).then((user) ->
```
Pass in the user to be logged in through the request.
```coffeescript
            req.loggingInUser = user
```
Invoke the `beforeLogin` middleware.
```coffeescript
            new Promise (resolve, reject) ->
              beforeLoginMiddleware.dispatch req, (error) ->
                return reject error if error?
                resolve user

          ).nodeify done

        next()

    ]
```
#### Implements hook `shrubHttpMiddleware`.
```coffeescript
  registrar.registerHook 'shrubHttpMiddleware', ->

    label: 'Load user using passport'
    middleware: passportMiddleware()
```
#### Implements hook `shrubRpcRoutesAlter`.
```coffeescript
  registrar.registerHook 'shrubRpcRoutesAlter', (routes) ->

    {spliceRouteMiddleware} = require 'shrub-rpc'
```
Implement `req.loadUser`.
```coffeescript
    loadUserMiddleware = (req, res, next) ->
```
Bootstrap Passport into a request.
```coffeescript
      req.loadUser = (done) -> req.loadSession ->

        passportMiddleware_ = new Middleware()
        passportMiddleware_.use fn for fn in passportMiddleware()
        passportMiddleware_.dispatch req, res, (error) ->
          return next error if error?
          done()

      next()
```
Make sure loadUser is available early.
```coffeescript
    loadUserMiddleware.weight = -4999

    for path, route of routes
```
Prepend the loadUser bootstrapping.
```coffeescript
      route.middleware.unshift loadUserMiddleware
```
Splice in Passport middleware.
```coffeescript
      spliceRouteMiddleware route, 'shrub-passport', passportMiddleware()

    return
```
#### Implements hook `shrubSocketConnectionMiddleware`.
```coffeescript
  registrar.registerHook 'shrubSocketConnectionMiddleware', ->

    label: 'Load user using passport'
```
Join a channel for the username.
```coffeescript
    middleware: passportMiddleware()

  registrar.recur [
    'logout'
  ]

passportMiddleware = -> [
```
Passport middleware.
```coffeescript
  passport.initialize()
  passport.session()
```
Invoke after login middleware if a user already exists in the session.
```coffeescript
  (req, res, next) ->
    return next() unless req.user?

    promise = new Promise (resolve, reject) ->
      afterLoginMiddleware.dispatch req, (error) ->
        return reject error if error?
        resolve()

    promise.nodeify next

    promise.finally -> delete req.loggingInUser
```
Proxy req.log[iI]n to run our middleware, and
return a promise.
```coffeescript
  (req, res, next) ->

    login = req.login
    req.login = req.logIn = (user, fn) ->

      promise = new Promise (resolve, reject) ->

        req.loggingInUser = user

        beforeLoginMiddleware.dispatch req, (error) ->
          return reject error if error?

          login.call req, req.loggingInUser, (error) ->
            return reject error if error?

            afterLoginMiddleware.dispatch req, (error) ->
              return reject error if error?

              resolve()

      promise.finally -> delete req.loggingInUser

    next()
```
Proxy req.log[oO]ut to run our middleware, and
return a promise.
```coffeescript
  (req, res, next) ->

    logout = req.logout
    req.logout = req.logOut = ->

      req.loggingOutUser = req.user

      promise = new Promise (resolve, reject) ->

        beforeLogoutMiddleware.dispatch req, (error) ->
          return reject error if error?

          logout.call req

          afterLogoutMiddleware.dispatch req, (error) ->
            return reject error if error?

            resolve()

      promise.finally -> delete req.loggingOutUser

    next()
```
Save the user at the end of the request.
```coffeescript
  (req, res, next) ->

    end = res.end
    res.end = (data, encoding) ->
      res.end = end

      return res.end data, encoding unless req.user?.id

      req.user.save().finally -> res.end data, encoding

    next()

]
```
