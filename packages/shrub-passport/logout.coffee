# # User logout
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubRpcRoutes`.
  registrar.registerHook 'shrubRpcRoutes', ->

    routes = []

    # Log out.
    routes.push

      path: 'shrub-user/logout'

      middleware: [

        'shrub-http-express/session'
        'shrub-passport'

        (req, res, next) -> req.logOut().then(-> res.end()).catch next

      ]

    return routes
