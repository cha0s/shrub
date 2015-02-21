# User logout

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `route`.

      registrar.registerHook 'route', ->

        path: 'user/logout'

        controller: [
          '$location', 'shrub-user'
          ($location, user) ->
            return $location.path '/' unless user.isLoggedIn()

            user.logout().then -> $location.path '/'

        ]
