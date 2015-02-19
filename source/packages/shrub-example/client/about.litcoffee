# Example - About page

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `route`.

      registrar.registerHook 'route', ->

        path: 'about'
        title: 'About'

        controller: [
          '$http', '$scope'
          ($http, $scope) ->

            $scope.about = ''

Hit the route we created in the server-side of this package.

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

