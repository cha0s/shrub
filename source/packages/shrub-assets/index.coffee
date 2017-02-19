# Assets management

*Gather, build, and serve assets defined by packages.*

```coffeescript
config = require 'config'

assets = null

exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubAssetsMiddleware`](../../hooks#shrubassetsmiddleware)

```coffeescript
  registrar.registerHook 'shrubAssetsMiddleware', ->

    label: 'Shrub'
    middleware: [

      (assets, next) ->

        if 'production' is config.get 'NODE_ENV'
          assets.scripts.push '/lib/shrub/shrub.min.js'
        else
          assets.scripts.push '/lib/shrub/shrub.js'

        assets.styleSheets.push '/css/shrub.css'

        next()

    ]
```

#### Implements hook [`shrubGruntConfig`](../../hooks#shrubgruntconfig)

```coffeescript
  registrar.registerHook 'shrubGruntConfig', (gruntConfig) ->

    gruntConfig.copyAppFiles "#{__dirname}/app", 'shrub-assets'

    gruntConfig.registerTask 'build:shrub-assets', [
      'newer:copy:shrub-assets'
    ]

    gruntConfig.registerTask 'build', ['build:shrub-assets']
```

#### Implements hook [`shrubConfigServer`](../../hooks#shrubconfigserver)

```coffeescript
  registrar.registerHook 'shrubConfigServer', ->

    middleware: [
      'shrub-assets/jquery'
      'shrub-socket-socket.io'
      'shrub-angular'
      'shrub-assets'
      'shrub-html5-notification'
      'shrub-html5-local-storage'
      'shrub-config'
      'shrub-grunt'
    ]

  registrar.recur [
    'jquery'
  ]

exports.assets = ->
  return assets if assets?

  debug = require('debug') 'shrub-silly:assets:middleware'

  middleware = require 'middleware'

  assets = scripts: [], styleSheets: []
```

#### Invoke hook [`shrubAssetsMiddleware`](../../hooks#shrubassetsmiddleware)

```coffeescript
  debug '- Loading asset middleware...'

  assetsMiddleware = middleware.fromConfig 'shrub-assets:middleware'

  debug '- Asset middleware loaded.'

  assetsMiddleware.dispatch assets, (error) -> throw error if error?

  assets
```
