# Example - Home page
```coffeescript
exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubAngularAppConfig`.
```coffeescript
  registrar.registerHook 'shrubAngularAppConfig', -> [
    '$routeProvider'
    ($routeProvider) ->
```
We'll gank the default route.
```coffeescript
      $routeProvider.otherwise redirectTo: '/home'
  ]
```
#### Implements hook `shrubAngularRoutes`.
```coffeescript
  registrar.registerHook 'shrubAngularRoutes', ->

    routes = []

    routes.push

      path: 'home'
      title: 'Home'

      template: '''

<div class="jumbotron">

  <h1>Shrub</h1>

  <p class="lead">Welcome to the example application for Shrub!</p>

</div>

'''

    return routes
```
