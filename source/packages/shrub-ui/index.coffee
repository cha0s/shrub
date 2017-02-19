# User Interface

```coffeescript
errors = require 'errors'

exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubConfigClient`](../../../hooks#shrubconfigclient)

```coffeescript
  registrar.registerHook 'shrubConfigClient', (req) ->
    config = {}

    if req.session?

      errorMessages = req.session.errorMessages ? []
      delete req.session.errorMessages
      config.errorMessages = errorMessages

    return config

  registrar.recur [
    'notifications'
  ]
```
