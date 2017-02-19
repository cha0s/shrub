# Example - About page

```coffeescript
exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubAngularRoutes`](../../../hooks#shrubangularroutes)

```coffeescript
  registrar.registerHook 'shrubAngularRoutes', ->

    routes = []

    routes.push

      path: 'about'
      title: 'About'

      controller: [
        '$http', '$scope'
        ($http, $scope) ->

          $scope.about = ''
```

Hit the route we created in the server-side of this package.

```coffeescript
          $http.get('/shrub-example/about/README.md').success((data) ->
            $scope.about = data
          )

      ]

      template: '''

<span
  class="about"
  data-ng-bind-html="about | shrubUiMarkdown:false"
></span>

'''

    return routes
```
