# HTML5 local storage

*Build and serve the HTML5 localStorage support.*

```coffeescript
exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubGruntConfig`](../../hooks#shrubgruntconfig)

```coffeescript
  registrar.registerHook 'shrubGruntConfig', (gruntConfig) ->

    gruntConfig.copyAppFiles "#{__dirname}/app", 'shrub-html5-local-storage'

    gruntConfig.registerTask 'build:shrub-html5-local-storage', [
      'newer:copy:shrub-html5-local-storage'
    ]

    gruntConfig.registerTask 'build', ['build:shrub-html5-local-storage']
```

#### Implements hook [`shrubAssetsMiddleware`](../../hooks#shrubassetsmiddleware)

```coffeescript
  registrar.registerHook 'shrubAssetsMiddleware', ->

    config = require 'config'

    label: 'Angular HTML5 local storage'
    middleware: [

      (assets, next) ->

        if 'production' is config.get 'NODE_ENV'
          assets.scripts.push '/lib/angular/angular-local-storage.min.js'
        else
          assets.scripts.push '/lib/angular/angular-local-storage.js'

        next()

    ]
```

#### Implements hook [`shrubAngularPackageDependencies`](../../hooks#shrubangularpackagedependencies)

```coffeescript
  registrar.registerHook 'shrubAngularPackageDependencies', -> [
    'LocalStorageModule'
  ]
```
