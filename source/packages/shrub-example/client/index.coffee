# Example package

```coffeescript
exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubSkinLink--DIRECTIVE`](../../../../hooks#shrubskinlink--directive)

```coffeescript
  registrar.registerHook 'shrubSkinLink--shrubSkinStrappedMainNav', -> [
    '$scope'
    ($scope) ->
```

Not ideal, but it's what we have right now.

```coffeescript
      $scope.menu.items.push
        path: 'home'
        label: 'Home'

      $scope.menu.items.push
        path: 'about'
        label: 'About'

  ]

  registrar.recur [
    'about', 'home'
  ]
```
