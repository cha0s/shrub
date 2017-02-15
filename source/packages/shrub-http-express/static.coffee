# Express - static files
```coffeescript
exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubHttpMiddleware`.

Serve static files.
```coffeescript
  registrar.registerHook 'shrubHttpMiddleware', (http) ->

    express = require 'express'

    config = require 'config'

    label: 'Serve static files'
    middleware: [
      express.static config.get 'packageSettings:shrub-http:path'
    ]
```
