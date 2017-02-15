# Example - About page

*Define a route to access the README.md page.*
```coffeescript
fs = require 'fs'

exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubHttpRoutes`.
```coffeescript
  registrar.registerHook 'shrubHttpRoutes', (http) ->
    routes = []
```
Provide the README file.
```coffeescript
    routes.push
      path: '/shrub-example/about/README.md'
      receiver: (req, res) ->

        fs.readFile 'README.md', (error, buffer) ->
          throw error if error?

          res.end buffer

    return routes
```
