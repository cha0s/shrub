# Example - About page

*Define a route to access the README.md page.*

    fs = require 'fs'

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `httpRoutes`.

      registrar.registerHook 'httpRoutes', (http) ->
        routes = []

Provide the README file.

        routes.push
          path: '/shrub-example/about/README.md'
          receiver: (req, res) ->

            fs.readFile 'README.md', (error, buffer) ->
              throw error if error?

              res.end buffer

        console.log routes

        return routes
