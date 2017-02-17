# User Interface
```coffeescript
errors = require 'errors'

exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubConfigClient`.
```coffeescript
  registrar.registerHook 'shrubConfigClient', (req) ->
    config = {}

    errorMessages = req.session.errorMessages
    delete req.session.errorMessages
    config.errorMessages = errorMessages

    return config

  registrar.recur [
    'notifications'
  ]
```
