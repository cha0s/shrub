
Promise = null

clientModule = require './client/login'
userPackage = require './index'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubCorePreBootstrap`.
  registrar.registerHook 'shrubCorePreBootstrap', ->

    Promise = require 'bluebird'

  # #### Implements hook `shrubRpcRoutes`.
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

          # Log the user in (if it exists), and redact it for the response.
          req.authorize(req.body.method, res).bind({}).then((@user, info) ->

            req.logIn @user

          ).then(->

            @user.redactObject 'shrub-user', @user

          ).then((user) ->

            console.log user

            res.end user

          ).catch next

      ]

    return routes

  # #### Implements hook `shrubConfigServer`.
  registrar.registerHook 'shrubConfigServer', ->

    beforeLoginMiddleware: []

    afterLoginMiddleware: []

    beforeLogoutMiddleware: [
      'shrub-passport'
    ]

    afterLogoutMiddleware: [
      'shrub-passport'
    ]

  # #### Implements hook `shrubCoreBootstrapMiddleware`.
  registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

    orm = require 'shrub-orm'

    crypto = require 'server/crypto'

    label: 'Bootstrap user login'
    middleware: [

      (next) ->

        next()

    ]
