# # User logout
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubAngularRoutes`.
  registrar.registerHook 'shrubAngularRoutes', ->

    routes = []

    routes.push

      path: 'user/logout'

      controller: [
        '$location', 'shrub-user'
        ($location, user) ->
          return $location.path '/' unless user.isLoggedIn()

          user.logout().then -> $location.path '/'

      ]

    return routes