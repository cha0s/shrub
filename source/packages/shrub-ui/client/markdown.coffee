# UI - Markdown
```coffeescript
marked = require 'marked'

exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubAngularFilter`
```coffeescript
  registrar.registerHook 'shrubAngularFilter', -> ->

    (input, sanitize = true) -> marked input, sanitize: sanitize
```
