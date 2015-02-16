# Abstract middleware stacks

    {EventEmitter} = require 'events'

    config = require 'config'
    pkgman = require 'pkgman'

    exports.Middleware = class Middleware extends EventEmitter

Implements a middleware stack. Middleware functions can be added to the stack
with `use`. Calling `dispatch` invokes the middleware functions serially.

Each middleware accepts an arbitrary parameters and finally a `next` function.
When a middleware finishes, it must call the `next` function. If there was an
error, it must be thrown or passed as the first argument to `next`. If no error
occurred, `next` must be invoked without arguments.

Error-handling middleware can also be defined. These middleware take an
additional parameter at the beginning of the function signature: `error`.
Error-handling middleware are only called if a previous middleware threw or
passed an error. Conversely, non-error-handling middleware are skipped if a
previous error occurred.

## *constructor*

*Create a middleware stack.*

      constructor: -> @_middleware = []

## Middlware#use

* (function) `fn` - A middleware function.

*Add a middleware function to the stack.*

      use: (fn) -> @_middleware.push fn

## Middleware#dispatch

* (mixed) `...` - One or more values to pass to the middleware.
* (function) `fn` - A function invoked when the middleware stack has
  finished. If an error occurred, it will be passed as the first
  argument.

*Invoke the middleware functions serially.*

      dispatch: (args..., fn) ->
        self = this

        index = 0

        invoke = (error) ->

          self.emit 'invoked', self._middleware[index - 1] if index > 0

Call `fn` with any error if we're done.

          return fn error if index is self._middleware.length

          current = self._middleware[index++]

Error-handling middleware.

          if current.length is args.length + 2

An error occurred previously.

            if error?

Try to invoke the middleware, if it throws, just catch the error and pass it
along.

              try
                localArgs = args.concat()
                localArgs.unshift error
                localArgs.push invoke
                self.emit 'invoking', current
                current localArgs...
              catch error
                invoke error

No previous error; skip this middleware.

            else

              invoke error

Non-error-handling middleware.

          else

An error occurred previously, skip this middleware.

            if error?

              invoke error

No previous error.

            else

Try to invoke the middleware, if it throws, just catch the error and pass it along.
              try
                localArgs = args.concat()
                localArgs.push invoke
                self.emit 'invoking', current
                current localArgs...
              catch error
                invoke error

Kick things off.

        invoke()

    debug = require('debug') 'shrub:middleware'
    debugSilly = require('debug') 'shrub-silly:middleware'

## middleware.fromHook

*Create a middleware stack from the results of a hook and path configuration.*

    exports.fromHook = (hook, paths, args...) ->

      middleware = new Middleware()

Invoke the hook and `use` the middleware in the paths configuration order.

      args.unshift hook
      hookResults = pkgman.invoke args...
      for path in paths ? []
        continue unless (spec = hookResults[path])?

        debugSilly "- - #{spec.label}"

        for fn in spec.middleware ? []
          fn.label = spec.label
          middleware.use fn, spec.label

      middleware.on 'invoking', (fn) -> debugSilly "Invoking #{fn.label}"
      middleware.on 'invoked', (fn) -> debugSilly "Invoked #{fn.label}"

      middleware

## middleware.fromShortName

*Create a middleware stack from a short name. e.g. "example thing hook".*

The short name is converted into log messages, a hook name, and configuration
key. In the case where we passed in "user before login", this would look
like:

```coffeescript
debug "Loading user before login middleware..."

middleware = exports.fromHook(
	"userBeforeLoginMiddleware"
	config.get "packageSettings:user:beforeLoginMiddleware"
)

debug "User before login middleware loaded."
```

###### TODO: This is bad and it should go away.

    exports.fromShortName = (shortName, packageName) ->

      i8n = require 'inflection'

      debugSilly "- Loading #{shortName} middleware..."

      [firstPart, keyParts...] = shortName.split ' '
      packageName ?= firstPart
      key = keyParts.join '_'

###### TODO: this really should be unified, making this unnecessary.

      configKey = if global? then 'packageSettings' else 'packageConfig'

      middleware = exports.fromHook(
        "#{firstPart}#{i8n.camelize key}Middleware"

        config.get "#{configKey}:#{packageName}:#{
          i8n.camelize key, true
        }Middleware"
      )

      debugSilly "- #{i8n.capitalize shortName} middleware loaded."

      middleware
