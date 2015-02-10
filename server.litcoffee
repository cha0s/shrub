
# Server application entry point

*Load the configuration, invoke the bootstrap hooks, and listen for signals
and process exit.*

The core bootstrap phase injects environment into a forked copy of the
application including require paths to allow core and custom packages to be
included without qualification.

    {fork} = require "./server/bootstrap"
    unless fork()

      Promise = require 'bluebird'

      debug = require('debug') 'shrub:server'
      debugSilly = require('debug') 'shrub-silly:server'

      errors = require 'errors'
      middleware = require 'middleware'
      pkgman = require 'pkgman'

Load the configuration.

      debug 'Loading config...'

      config = require 'config'
      config.load()
      config.loadPackageSettings()

      debug 'Config loaded.'

#### Invoke hook `preBootstrap`.

Invoked before the application bootstrap phase. This allows applications to
reference modules or other pakcages which greatly speeds up the `require`
process for those packages. This is important to keep the build process as fast
as possible.

If your package `require`s heavy modules, you should require them in an
implementation of hook `preBootstrap`. For instance, say you have a package
like:

```coffeescript
someHeavyModule = require 'some-heavy-module'

exports.pkgmanRegister = (registrar) ->

  registrar.registerHook 'someHook', ->

    someHeavyModule.doSomething()
```

This will slow the build process down, since `some-heavy-module` must be
loaded when loading your package. Use this pattern instead:

```coffeescript
someHeavyModule = null

exports.pkgmanRegister = (registrar) ->

  registrar.registerHook 'preBootstrap', ->

    someHeavyModule = require 'some-heavy-module'

  registrar.registerHook 'someHook', ->

    someHeavyModule.doSomething()
```

So that the heavy module will not be `require`d until hook `preBootstrap` is
invoked.

###### TODO: Link to an instance of this in shrub core.

      debugSilly 'Pre bootstrap phase...'
      pkgman.invoke 'preBootstrap'
      debugSilly 'Pre bootstrap phase completed.'

#### Invoke hook `bootstrapMiddleware`.

Invoked during the application bootstrap phase. Packages implementing this hook
should return an instance of `MiddlewareGroup`.

###### TODO: Link to an instance of this in shrub core.

###### TODO: Currently middleware hook implementations return an ad-hoc structure, but MiddlewareGroup will be the preferred mechanism in the future.

This is where the real heavy-lifting instantiation occurs. For instance, this
is where the HTTP server is constructed by `shrub-http` and made to listen on
a port, where `shrub-nodemailer` instantiates its sandbox, etc.

      debugSilly 'Loading bootstrap middleware...'
      bootstrapMiddleware = middleware.fromHook(
        'bootstrapMiddleware'
        config.get 'packageSettings:shrub-core:bootstrapMiddleware'
      )
      debugSilly 'Bootstrap middleware loaded.'

Dispatch the bootstrap middleware stack and log if everything is okay.

      bootstrapMiddleware.dispatch (error) ->
        return debug 'Bootstrap complete.' unless error?

Log and throw any error. This will be caught by the unhandledException
listener below.

        console.error errors.stack error
        throw error

#### Invoke hook `processExit`.

We do our best to guarantee that hook `processExit` will always be invoked,
even when an exception or signal arises.

###### TODO: Link to an instance of this in shrub core.

      process.on 'exit', -> pkgman.invoke 'processExit'

      process.on 'SIGINT', -> process.exit()
      process.on 'SIGTERM', -> process.exit()
      process.on 'unhandledException', -> process.exit()
