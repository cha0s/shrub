# Socket

*Provide an Angular service wrapping a real-time socket.*
```coffeescript
config = require 'config'

exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubAngularService`.
```coffeescript
  registrar.registerHook 'shrubAngularService', ->
```
Load the manager module.
```coffeescript
    {Manager} = require config.get 'packageConfig:shrub-socket:manager:module'
    Manager
```
