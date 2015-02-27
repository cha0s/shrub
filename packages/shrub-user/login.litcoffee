
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

        {Limiter} = require 'shrub-limiter'

        routes = []

        routes.push

          limiter:
            message: 'You are logging in too much.'
            threshold: Limiter.threshold(3).every(30).seconds()

          path: 'shrub-user/login'

          receiver: (req, fn) ->

            errors = require 'errors'

            passport = req._passport.instance

            loginPromise = switch req.body.method

              when 'local'

                res = {}
                deferred = Promise.defer()
                passport.authenticate('local', deferred.callback) req, res, fn

Log the user in (if it exists), and redact it for the response.

                deferred.promise.bind({}).spread((@user, info) ->
                  throw errors.instantiate 'login' unless @user

                  req.logIn @user

                ).then(->

                  new Promise (resolve, reject) =>

Join a channel for the username.

                    req.socket.join @user.name, (error) ->
                      return reject error if error?

                      resolve()

                ).then ->

                  @user.redactFor @user

            loginPromise.then((user) -> fn null, user).catch fn

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

            monkeyPatchLogin()

            next()

        ]

#### Implements hook `shrubTransmittableErrors`.

      registrar.registerHook 'shrubTransmittableErrors', clientModule.shrubTransmittableErrors

Monkey patch http.IncomingMessage.prototype.login to run our middleware, and
return a promise.

    monkeyPatchLogin = ->

      {IncomingMessage} = require 'http'

      middleware = require 'middleware'

      req = IncomingMessage.prototype

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
