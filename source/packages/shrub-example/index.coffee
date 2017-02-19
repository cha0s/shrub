# Example package

```coffeescript
exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubRpcRoutesAlter`](../../../hooks#shrubrpcroutesalter)

Our notification queue uses the session, so we'll alter those routes to
load the session if it's for the shrubExampleGeneral queue.

```coffeescript
  registrar.registerHook 'shrubRpcRoutesAlter', (routes) ->

    for path, route of routes
      if path.match /^shrub-ui\/notifications.*/
        route.middleware.unshift (req, res, next) ->
          if 'shrubExampleGeneral' is req.body.queue
            return req.loadSession next
          next()

    return
```

#### Implements hook [`shrubUiNotificationQueues`](../../../hooks#shrubuinotificationqueues)

Implement the `general` queue, used to show some notifications.

```coffeescript
  registrar.registerHook 'shrubUiNotificationQueues', ->

    shrubExampleGeneral:

      channelFromRequest: (req) -> req.session?.id

  registrar.recur [
    'about'
  ]
```
