# Socket

*Provide an Angular service wrapping a real-time socket.*

    config = require 'config'

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubAngularService`.

      registrar.registerHook 'shrubAngularService', ->

Load the manager module.

        {Manager} = require config.get 'packageConfig:shrub-socket:manager:module'
        Manager
