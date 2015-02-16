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

Invoked before the application bootstrap phase.

[See the `preBootstrap` hook documentation](hooks#prebootstrap)

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
