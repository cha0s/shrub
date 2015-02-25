# Example - Home page

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubAngularAppConfig`.

      registrar.registerHook 'shrubAngularAppConfig', -> [
        '$routeProvider'
        ($routeProvider) ->

We'll gank the default route.

          $routeProvider.otherwise redirectTo: '/home'
      ]

#### Implements hook `shrubAngularRoutes`.

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
