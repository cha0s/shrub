# Express - routes

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubHttpMiddleware`.

Serve Express routes.

      registrar.registerHook 'shrubHttpMiddleware', (http) ->

        label: 'Serve routes'
        middleware: [
          http._app.router
        ]
