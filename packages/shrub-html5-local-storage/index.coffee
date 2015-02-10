
exports.pkgmanRegister = (registrar) ->

  # ## Implements hook `gruntConfig`
  registrar.registerHook 'gruntConfig', (gruntConfig) ->

    gruntConfig.configureTask 'copy', 'shrub-html5-local-storage', files: [
      src: '**/*'
      dest: 'app'
      expand: true
      cwd: "#{__dirname}/app"
    ]

    gruntConfig.configureTask(
      'watch', 'shrub-html5-local-storage'

      files: [
        "#{__dirname}/app/**/*"
      ]
      tasks: 'build:shrub-html5-local-storage'
    )

    gruntConfig.registerTask 'build:shrub-html5-local-storage', [
      'newer:copy:shrub-html5-local-storage'
    ]

    gruntConfig.registerTask 'build', ['build:shrub-html5-local-storage']

  # ## Implements hook `assetMiddleware`
  registrar.registerHook 'assetMiddleware', ->

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

  # ## Implements hook `angularPackageDependencies`
  registrar.registerHook 'angularPackageDependencies', -> [
    'LocalStorageModule'
  ]
