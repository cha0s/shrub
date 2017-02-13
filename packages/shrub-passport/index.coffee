# # Passport integration

# *Authentication system, leaning on [passport](http://passportjs.org).*

pkgman = require 'pkgman'

orm = null
passport = null
Promise = null

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubCorePreBootstrap`.
  registrar.registerHook 'shrubCorePreBootstrap', ->

    orm = require 'shrub-orm'
    passport = require 'passport'
    Promise = require 'bluebird'

  # #### Implements hook `shrubCoreBootstrapMiddleware`.
  registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

    Promise = require 'bluebird'

    middleware = require 'middleware'

    label: 'Bootstrap user authorization'
    middleware: [

      (next) ->

        {IncomingMessage} = require 'http'

        IncomingMessage::authorize = (method, res) ->
          self = this

          new Promise (resolve, reject) ->

            self._passport.instance.authenticate(
              method
              (error, user, info) ->
                return reject error if error?
                resolve user, info

            ) self, res

        for packageName, strategy of pkgman.invoke 'shrubUserLoginStrategies'
          passport.use strategy.passportStrategy

        passport.serializeUser (user, done) -> done null, user.id

        passport.deserializeUser (id, done) ->
          orm.collection('shrub-user').findOnePopulated(id: id).nodeify done

        next()

    ]

  # #### Implements hook `shrubHttpMiddleware`.
  registrar.registerHook 'shrubHttpMiddleware', ->

    label: 'Load user using passport'
    middleware: passportMiddleware()

  # #### Implements hook `shrubRpcRoutesAlter`.
  registrar.registerHook 'shrubRpcRoutesAlter', (routes) ->

    {spliceRouteMiddleware} = require 'shrub-rpc'

    loadUserMiddleware = (req, res, next) ->

      req.loadUser = (done) -> req.loadSession ->

        passportMiddleware_ = new Middleware()
        for fn in passportMiddleware()
          passportMiddleware_.use fn

        passportMiddleware_.dispatch req, res, (error) ->
          return next error if error?
          done()

      next()

    loadUserMiddleware.weight = -4999

    for path, route of routes
      route.middleware.unshift loadUserMiddleware
      spliceRouteMiddleware route, 'shrub-passport', passportMiddleware()

    return

  # #### Implements hook `shrubSocketConnectionMiddleware`.
  registrar.registerHook 'shrubSocketConnectionMiddleware', ->

    label: 'Load user using passport'

    # Join a channel for the username.
    middleware: passportMiddleware().concat (req, res, next) ->

      return req.socket.join "user/#{req.user.id}", next if req.user.id?

      next()

  # #### Implements hook `shrubUserBeforeLogoutMiddleware`.
  registrar.registerHook 'shrubUserBeforeLogoutMiddleware', ->

    label: 'Tell client to log out, and leave the user channel'
    middleware: [

      (req, next) ->

        return next() unless req.socket?

        # Tell client to log out.
        req.socket.emit 'shrub-user/logout'

        # Leave the user channel.
        if req.user.id?
          req.socket.leave req.user.name, next
        else
          next()

    ]

  registrar.recur [
    'logout'
  ]

passportMiddleware = -> [

  (req, res, next) ->

    req.instantiateAnonymous = ->

      @user = orm.collection('shrub-user').instantiate()

      # Add to anonymous group.
      @user.groups = [
        orm.collection('shrub-user-group').instantiate group: 2
      ]

      @user.populateAll()

    next()

  # Passport middleware.
  passport.initialize()
  passport.session()

  # Monkey patch http.IncomingMessage.prototype.login to run our middleware,
  # and return a promise.
  (req, res, next) ->

    middleware = require 'middleware'

    # #### Invoke hook `shrubUserBeforeLoginMiddleware`.
    beforeLoginMiddleware = middleware.fromConfig(
      'shrub-user:beforeLoginMiddleware'
    )

    # #### Invoke hook `shrubUserAfterLoginMiddleware`.
    afterLoginMiddleware = middleware.fromConfig(
      'shrub-user:afterLoginMiddleware'
    )

    login = req.passportLogIn = req.login
    req.login = req.logIn = (user, fn) ->

      new Promise (resolve, reject) ->

        loginReq = req: req, user: user

        beforeLoginMiddleware.dispatch loginReq, null, (error) =>
          return reject error if error?

          login.call req, loginReq.user, (error) ->
            return reject error if error?

            afterLoginMiddleware.dispatch loginReq, null, (error) ->
              return reject error if error?

              resolve()

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


