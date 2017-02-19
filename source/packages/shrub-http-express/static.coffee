# Express - static files

```coffeescript
exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubHttpMiddleware`](../../../hooks#shrubhttpmiddleware)

Serve static files.

```coffeescript
  registrar.registerHook 'shrubHttpMiddleware', (http) ->

    express = require 'express'

    config = require 'config'

    label: 'Serve static files'
    middleware: [
      express.static config.get 'packageConfig:shrub-http:path'
    ]
```
