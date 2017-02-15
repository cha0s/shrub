# User Interface

*User interface components.*
```coffeescript
exports.pkgmanRegister = (registrar) ->

  registrar.recur [
    'attributes', 'list', 'markdown', 'menu', 'messages', 'notifications'
    'window-title'
  ]
```
