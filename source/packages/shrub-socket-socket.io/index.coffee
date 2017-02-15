# Socket.IO

*Build and serve [Socket.IO](http://socket.io/).*
```coffeescript
exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubAssetsMiddleware`.
```coffeescript
  registrar.registerHook 'shrubAssetsMiddleware', ->

    config = require 'config'

    label: 'Socket.IO'
    middleware: [

      (assets, next) ->

        if 'production' is config.get 'NODE_ENV'

          assets.scripts.push '/lib/socket.io/socket.io.min.js'

        else

          assets.scripts.push '/lib/socket.io/socket.io.js'

        next()

    ]
```
#### Implements hook `shrubGruntConfig`.
```coffeescript
  registrar.registerHook 'shrubGruntConfig', (gruntConfig) ->

    gruntConfig.copyAppFiles "#{__dirname}/app", 'shrub-socket.io'

    gruntConfig.registerTask 'build:shrub-socket.io', [
      'newer:copy:shrub-socket.io'
    ]

    gruntConfig.registerTask 'build', ['build:shrub-socket.io']

exports.Manager = require './manager'
```
