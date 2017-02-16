# # Passport integration

# *Authentication system, leaning on [passport](http://passportjs.org).*

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

  # #### Implements hook `shrubCorePreBootstrap`.
  registrar.registerHook 'shrubCorePreBootstrap', ->

    orm = require 'shrub-orm'
    passport = require 'passport'
    Promise = require 'bluebird'

  # #### Implements hook `shrubCoreBootstrapMiddleware`.
  registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

    Promise = require 'bluebird'

    label: 'Bootstrap user authorization'
    middleware: [

      (next) ->

        {IncomingMessage} = require 'http'

        # ## IncomingMessage::authorize
        #
        # * (string) `method` - The authorization method.
        #
        # * (response) `res` - The HTTP/socket response object.
        #
        # *Authorize a user instance.*
        IncomingMessage::authorize = (method, res) ->
          self = this

          new Promise (resolve, reject) ->

            self._passport.instance.authenticate(
              method
              (error, user, info) ->
                return reject error if error?
                resolve user, info

            ) self, res

        # #### Invoke hook `shrubUserBeforeLoginMiddleware`.
        beforeLoginMiddleware = middleware.fromConfig(
          'shrub-user:beforeLoginMiddleware'
        )

        # #### Invoke hook `shrubUserAfterLoginMiddleware`.
        afterLoginMiddleware = middleware.fromConfig(
          'shrub-user:afterLoginMiddleware'
        )

        # #### Invoke hook `shrubUserBeforeLogoutMiddleware`.
        beforeLogoutMiddleware = middleware.fromConfig(
          'shrub-user:beforeLogoutMiddleware'
        )

        # #### Invoke hook `shrubUserAfterLogoutMiddleware`.
        afterLogoutMiddleware = middleware.fromConfig(
          'shrub-user:afterLogoutMiddleware'
        )

        # #### Invoke hook `shrubUserLoginStrategies`.
        #
        # Use passport authorization strategies.
        strategies = pkgman.invoke 'shrubUserLoginStrategies'

        # #### Invoke hook `shrubUserLoginStrategiesAlter`.
        pkgman.invoke 'shrubUserLoginStrategiesAlter', strategies

        for packageName, strategy of strategies
          passport.use strategy.passportStrategy

        # Passport serialization callback. Store the user ID.
        passport.serializeUser (user, done) -> done null, user.id

        # Passport deserialization callback.
        passport.deserializeUser (req, id, done) ->

          # Load user based on ID
          promise = orm.collection(
            'shrub-user'
          ).findOnePopulated(
            id: id
          ).then((user) ->

            # Pass in the user to be logged in through the request.
            req.loggingInUser = user

            # Invoke the `beforeLogin` middleware.
            new Promise (resolve, reject) ->
              beforeLoginMiddleware.dispatch req, (error) ->
                return reject error if error?
                resolve user

          ).nodeify done

        next()

    ]

  # #### Implements hook `shrubHttpMiddleware`.
  registrar.registerHook 'shrubHttpMiddleware', ->

    label: 'Load user using passport'
    middleware: passportMiddleware()

  # #### Implements hook `shrubRpcRoutesAlter`.
  registrar.registerHook 'shrubRpcRoutesAlter', (routes) ->

    {spliceRouteMiddleware} = require 'shrub-rpc'

    # Implement `req.loadUser`.
    loadUserMiddleware = (req, res, next) ->

      # Bootstrap Passport into a request.
      req.loadUser = (done) -> req.loadSession ->

        passportMiddleware_ = new Middleware()
        passportMiddleware_.use fn for fn in passportMiddleware()
        passportMiddleware_.dispatch req, res, (error) ->
          return next error if error?
          done()

      next()

    # Make sure loadUser is available early.
    loadUserMiddleware.weight = -4999

    for path, route of routes
      # Prepend the loadUser bootstrapping.
      route.middleware.unshift loadUserMiddleware

      # Splice in Passport middleware.
      spliceRouteMiddleware route, 'shrub-passport', passportMiddleware()

    return

  # #### Implements hook `shrubSocketConnectionMiddleware`.
  registrar.registerHook 'shrubSocketConnectionMiddleware', ->

    label: 'Load user using passport'

    # Join a channel for the username.
    middleware: passportMiddleware()

  registrar.recur [
    'logout'
  ]

passportMiddleware = -> [

  # Passport middleware.
  passport.initialize()
  passport.session()

  # Invoke after login middleware if a user already exists in the session.
  (req, res, next) ->
    return next() unless req.user?

    promise = new Promise (resolve, reject) ->
      afterLoginMiddleware.dispatch req, (error) ->
        return reject error if error?
        resolve()

    promise.nodeify next

    promise.finally -> delete req.loggingInUser

  # Proxy req.log[iI]n to run our middleware, and
  # return a promise.
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

  # Proxy req.log[oO]ut to run our middleware, and
  # return a promise.
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

  # Save the user at the end of the request.
  (req, res, next) ->

    end = res.end
    res.end = (data, encoding) ->
      res.end = end

      return res.end data, encoding unless req.user?.id

      req.user.save().finally -> res.end data, encoding

    next()

]


