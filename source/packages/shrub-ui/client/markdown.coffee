# UI - Markdown

```coffeescript
marked = require 'marked'

exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubAngularFilter`](../../../../hooks#shrubangularfilter)

```coffeescript
  registrar.registerHook 'shrubAngularFilter', -> ->

    (input, sanitize = true) -> marked input, sanitize: sanitize
```
