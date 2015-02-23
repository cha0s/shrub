# User logout

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `rpcRoutes`.

      registrar.registerHook 'rpcRoutes', ->

        routes = []

        routes.push

          path: 'shrub-user/logout'

Log out.

          receiver: (req, fn) -> req.logOut().nodeify fn

        return routes

#### Implements hook `bootstrapMiddleware`.

      registrar.registerHook 'bootstrapMiddleware', ->

        Promise = require 'bluebird'

        middleware = require 'middleware'

        label: 'Bootstrap user logout'
        middleware: [

          (next) ->

            {IncomingMessage} = require 'http'

            req = IncomingMessage.prototype

#### Invoke hook `userBeforeLogoutMiddleware`.

            userBeforeLogoutMiddleware = middleware.fromShortName(
              'user before logout'
              'shrub-user'
            )

#### Invoke hook `userAfterLogoutMiddleware`.

            userAfterLogoutMiddleware = middleware.fromShortName(
              'user after logout'
              'shrub-user'
            )

            logout = req.passportLogOut = req.logout
            req.logout = req.logOut = ->
              self = this

              new Promise (resolve, reject) ->

                userBeforeLogoutMiddleware.dispatch self, (error) ->
                  return reject error if error?

                  logout.call self

                  userAfterLogoutMiddleware.dispatch self, (error) ->
                    return reject error if error?

                    resolve()

            next()

        ]
