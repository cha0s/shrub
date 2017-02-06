# # HTML5 notification
#
# *Build and serve the HTML5 notification support.*
config = require 'config'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubGruntConfig`.
  registrar.registerHook 'shrubGruntConfig', (gruntConfig) ->

    gruntConfig.copyAppFiles "#{__dirname}/app", 'shrub-html5-notification'

    gruntConfig.registerTask 'build:shrub-html5-notification', [
      'newer:copy:shrub-html5-notification'
    ]

    gruntConfig.registerTask 'build', ['build:shrub-html5-notification']

  # #### Implements hook `shrubAssetsMiddleware`.
  registrar.registerHook 'shrubAssetsMiddleware', ->

    label: 'Angular HTML5 notifications'
    middleware: [

      (assets, next) ->

        if 'production' is config.get 'NODE_ENV'
          assets.scripts.push '/lib/angular/angular-notification.min.js'
        else
          assets.scripts.push '/lib/angular/angular-notification.js'

        next()

    ]

  # #### Implements hook `shrubAngularPackageDependencies`.
  registrar.registerHook 'shrubAngularPackageDependencies', -> [
    'notification'
  ]