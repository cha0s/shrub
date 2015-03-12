# Example package

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubSkinLink--DIRECTIVE`.

      registrar.registerHook 'shrubSkinLink--shrubSkinStrappedMainNav', -> [
        '$scope'
        ($scope) ->

Not ideal, but it's what we have right now.

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
