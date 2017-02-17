# Server application entry point

*Load the configuration, invoke the bootstrap hooks, and listen for signals
and process exit.* The core bootstrap phase injects environment into a
forked copy of the application including require paths to allow core and
custom packages to be included without qualification.
```coffeescript
{fork} = require "./server/bootstrap"
unless fork()

  Promise = require 'bluebird'

  debug = require('debug') 'shrub:server'
  debugSilly = require('debug') 'shrub-silly:server'

  config = require 'config'
  errors = require 'errors'
  middleware = require 'middleware'
  pkgman = require 'pkgman'
```
Set up exit hooks.

#### Invoke hook `shrubCoreProcessExit`.
```coffeescript
  process.on 'exit', -> pkgman.invoke 'shrubCoreProcessExit'

  process.on 'SIGINT', -> process.exit()
  process.on 'SIGTERM', -> process.exit()
  process.on 'unhandledException', -> process.exit()
```
Load the configuration.
```coffeescript
  debug 'Loading config...'

  config.load()
  config.loadPackageSettings()

  debug 'Config loaded.'
```
#### Invoke hook `shrubCorePreBootstrap`.
```coffeescript
  debugSilly 'Pre bootstrap phase...'
  pkgman.invoke 'shrubCorePreBootstrap'
  debugSilly 'Pre bootstrap phase completed.'
```
#### Invoke hook `shrubCoreBootstrapMiddleware`.
```coffeescript
  debugSilly 'Loading bootstrap middleware...'

  bootstrapMiddleware = middleware.fromConfig(
    'shrub-core:bootstrapMiddleware'
  )

  debugSilly 'Bootstrap middleware loaded.'
```
Dispatch the bootstrap middleware stack and log if everything is okay.
```coffeescript
  bootstrapMiddleware.dispatch (error) ->
    return debug 'Bootstrap complete.' unless error?
```
Log and throw any error. This will be caught by the unhandledException
listener below.
```coffeescript
    console.error errors.stack error
    process.exit()
```
