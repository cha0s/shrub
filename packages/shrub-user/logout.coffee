# # User logout
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubRpcRoutes`.
  registrar.registerHook 'shrubRpcRoutes', ->

    routes = []

    routes.push

      path: 'shrub-user/logout'

      # Log out.
      middleware: [

        'shrub-http-express/session'
        'shrub-user'

        (req, res, next) -> req.logOut().then(-> res.end()).catch next

      ]

    return routes

  # #### Implements hook `shrubCoreBootstrapMiddleware`.
  registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

    Promise = require 'bluebird'

    middleware = require 'middleware'

    label: 'Bootstrap user logout'
    middleware: [

      (next) ->

        {IncomingMessage} = require 'http'

        req = IncomingMessage.prototype

        # #### Invoke hook `shrubUserBeforeLogoutMiddleware`.
        beforeLogoutMiddleware = middleware.fromConfig(
          'shrub-user:beforeLogoutMiddleware'
        )

        # #### Invoke hook `shrubUserAfterLogoutMiddleware`.
        afterLogoutMiddleware = middleware.fromConfig(
          'shrub-user:afterLogoutMiddleware'
        )

        logout = req.passportLogOut = req.logout
        req.logout = req.logOut = ->
          self = this

          new Promise (resolve, reject) ->

            beforeLogoutMiddleware.dispatch self, (error) ->
              return reject error if error?

              logout.call self

              afterLogoutMiddleware.dispatch self, (error) ->
                return reject error if error?

                resolve()

        next()

    ]