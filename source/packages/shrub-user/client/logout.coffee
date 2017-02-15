# User logout
```coffeescript
exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubAngularRoutes`.
```coffeescript
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
```
