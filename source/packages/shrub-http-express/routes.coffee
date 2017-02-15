# Express - routes
```coffeescript
exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubHttpMiddleware`.

Serve Express routes.
```coffeescript
  registrar.registerHook 'shrubHttpMiddleware', (http) ->

    label: 'Serve routes'
    middleware: [
      exports.routeSentinel
    ]

exports.routeSentinel = ->
```
