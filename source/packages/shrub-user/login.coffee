```coffeescript

errors = require 'errors'

orm = null
Promise = null

clientModule = require './client/login'
userPackage = require './index'

exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubCorePreBootstrap`.
```coffeescript
  registrar.registerHook 'shrubCorePreBootstrap', ->

    orm = require 'shrub-orm'
    Promise = require 'bluebird'
```
#### Implements hook `shrubRpcRoutes`.
```coffeescript
  registrar.registerHook 'shrubRpcRoutes', ->

    {Limiter, LimiterMiddleware} = require 'shrub-limiter'

    routes = []

    routes.push

      path: 'shrub-user/login'

      middleware: [

        'shrub-http-express/session'
        'shrub-villiany'

        'shrub-passport'

        new LimiterMiddleware(
          message: 'You are logging in too much.'
          threshold: Limiter.threshold(3).every(30).seconds()
        )

        (req, res, next) ->
```
Authorize a user instance.
```coffeescript
          promise = req.authorize(
            req.body.method, res
          )

          exports.loginWithInstance(promise, req).then((user) ->
```
Redact the user for sending over the wire.
```coffeescript
            user.redactObject 'shrub-user', user
```
End the request, sending the redacted user.
```coffeescript
          ).then((redactedUser) -> res.end redactedUser).catch next


      ]

    return routes

exports.loginWithInstance = (promise, req) ->

  promise.then((instance, info) ->
```
Get any associated user.
```coffeescript
    instance.associatedUser()

  ).then((associatedUser) ->

    if associatedUser?

      if req.user?
```
If the user is already logged in and the instance has an
associated user, they're either already logged in with
the instance, or the instance belongs to another user. Throw
a relevant error either way.
```coffeescript
        if req.user.id is associatedUser.id

          throw errors.instantiate('shrub-user-login-redundant')

        else

          throw errors.instantiate('shrub-user-login-conflict')
```
If the user isn't already logged in, just return the user
associated with the instance.
```coffeescript
      else

        return associatedUser

    else
```
If the instance isn't already associated with a user, either
target the logged-in user, or if the user isn't already
logged in, target a new user.
```coffeescript
      promise = if req.user?

        Promise.resolve req.user

      else

        orm.collection('shrub-user').create()
```
Associate the instance with the user targeted just above.
```coffeescript
      promise.then (user) ->

        user.instances.add(
          model: instance.model
          modelId: instance.id
        )

        user.save().then -> return user
```
Log in the user if not already logged in.
```coffeescript
  ).then (user) ->

    req.logIn user unless req.user?
    return user
```
