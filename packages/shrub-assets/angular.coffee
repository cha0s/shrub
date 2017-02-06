# # Angular assets
config = require 'config'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubAssetsMiddleware`.
  registrar.registerHook 'shrubAssetsMiddleware', ->

    label: 'Angular'
    middleware: [

      (assets, next) ->

        if 'production' is config.get 'NODE_ENV'

          assets.scripts.push '//ajax.googleapis.com/ajax/libs/angularjs/1.3.8/angular.min.js'
          assets.scripts.push '//ajax.googleapis.com/ajax/libs/angularjs/1.3.8/angular-route.min.js'
          assets.scripts.push '//ajax.googleapis.com/ajax/libs/angularjs/1.3.8/angular-sanitize.min.js'

        else

          assets.scripts.push '/lib/angular/angular.js'
          assets.scripts.push '/lib/angular/angular-route.js'
          assets.scripts.push '/lib/angular/angular-sanitize.js'

        next()

    ]