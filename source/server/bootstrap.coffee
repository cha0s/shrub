# Process bootstrap

*Bootstrap the server application by forking to ensure require paths are set
by default.*

```coffeescript
{fork} = require 'child_process'
```

## boostrap.fork

*Fork the process in order to inject require paths if necessary.*

```coffeescript
exports.fork = ->
```

If we've already forked, our work is done.

```coffeescript
  return null if process.env.SHRUB_FORKED?
```

Ensure we have default require paths.

```coffeescript
  SHRUB_REQUIRE_PATH = if process.env.SHRUB_REQUIRE_PATH?
    process.env.SHRUB_REQUIRE_PATH
  else
    'custom:.:packages:server:client/modules'
```

Pass all arguments to the child process.

```coffeescript
  args = process.argv.slice 2
```

Pass the environment to the child process.

```coffeescript
  options = env: process.env
```

Integrate any NODE_PATH after the shrub require paths.

```coffeescript
  if process.env.NODE_PATH?
    SHRUB_REQUIRE_PATH += ":#{process.env.NODE_PATH}"
```

Inject shrub require paths as the new NODE_PATH, and signal that we've
forked.

```coffeescript
  options.env.NODE_PATH = SHRUB_REQUIRE_PATH
  options.env.SHRUB_FORKED = true
```

Fork it.

```coffeescript
  fork process.argv[1], args, options
```
