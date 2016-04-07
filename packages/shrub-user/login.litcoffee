
    passport = null
    Promise = null

    clientModule = require './client/login'
    userPackage = require './index'

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubCorePreBootstrap`.

      registrar.registerHook 'shrubCorePreBootstrap', ->

        passport = require 'passport'
        Promise = require 'bluebird'

#### Implements hook `shrubRpcRoutes`.

      registrar.registerHook 'shrubRpcRoutes', ->

        {Limiter, LimiterMiddleware} = require 'shrub-limiter'

        routes = []

        routes.push

          path: 'shrub-user/login'

          middleware: [

            'shrub-http-express/session'
            'shrub-villiany'

            'shrub-user'

            new LimiterMiddleware(
              message: 'You are logging in too much.'
              threshold: Limiter.threshold(3).every(30).seconds()
            )

            (req, res, next) ->

              errors = require 'errors'

              promise = new Promise (resolve, reject) ->
                req._passport.instance.authenticate(
                  req.body.method
                  (error, user, info) ->
                    return reject error if error?
                    resolve user, info

                ) req, res

Log the user in (if it exists), and redact it for the response.

              promise.bind({}).then((@user, info) ->
                throw errors.instantiate 'login' unless @user

                req.logIn @user

              ).then(->

                new Promise (resolve, reject) =>

Join a channel for the username.

                  req.socket.join @user.name, (error) ->
                    return reject error if error?

                    resolve()

              ).then(->

                @user.redactFor @user

              ).then((user) -> res.end user).catch next

          ]

        return routes

#### Implements hook `shrubCoreBootstrapMiddleware`.

      registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

        orm = require 'shrub-orm'

        crypto = require 'server/crypto'

        label: 'Bootstrap user login'
        middleware: [

          (next) ->

Implement a local passport strategy.

###### TODO: Strategies should be dynamically defined through a hook.

            LocalStrategy = require('passport-local').Strategy
            passport.use new LocalStrategy (username, password, done) ->

Load a user and compare the hashed password.

              Promise.cast(
                userPackage.loadByName username
              ).bind({}).then((@user) ->
                return unless @user?

                crypto.hasher(
                  plaintext: password
                  salt: new Buffer @user.salt, 'hex'
                )

              ).then((hashed) ->
                return unless @user?
                return unless @user.passwordHash is hashed.key.toString(
                  'hex'
                )

                @user

              ).nodeify done

            passport.serializeUser (user, done) -> done null, user.id

            passport.deserializeUser (id, done) ->
              User = orm.collection 'shrub-user'
              User.findOne(id: id).populateAll().then((user) ->
                user.populateAll()
              ).then((user) -> done null, user).catch done

            next()

        ]

#### Implements hook `shrubTransmittableErrors`.

      registrar.registerHook 'shrubTransmittableErrors', clientModule.shrubTransmittableErrors

Monkey patch http.IncomingMessage.prototype.login to run our middleware, and
return a promise.

    exports.monkeyPatchLogin = (req, res, next) ->

      middleware = require 'middleware'

#### Invoke hook `shrubUserBeforeLoginMiddleware`.

      beforeLoginMiddleware = middleware.fromConfig(
        'shrub-user:beforeLoginMiddleware'
      )

#### Invoke hook `shrubUserAfterLoginMiddleware`.

      afterLoginMiddleware = middleware.fromConfig(
        'shrub-user:afterLoginMiddleware'
      )

      login = req.passportLogIn = req.login
      req.login = req.logIn = (user, fn) ->

        new Promise (resolve, reject) =>

          loginReq = req: this, user: user

          beforeLoginMiddleware.dispatch loginReq, null, (error) =>
            return reject error if error?

            login.call this, loginReq.user, (error) ->
              return reject error if error?

              afterLoginMiddleware.dispatch loginReq, null, (error) ->
                return reject error if error?

                resolve()

      next()
