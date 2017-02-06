# # Angular

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

  # #### Implements hook `shrubGruntConfig`.
  registrar.registerHook 'shrubGruntConfig', (gruntConfig, grunt) ->

    gruntConfig.configureTask(
      'coffee', 'angular'

      files: [
        src: [
          'client/app.coffee'
        ]
        dest: 'build/js/app/app.js'
      ]
      expand: true
      ext: '.js'
      options: bare: true
    )

    gruntConfig.configureTask(
      'concat', 'angular'

      files: [
        src: [
          'build/js/app/app-dependencies.js'
          'build/js/app/app.js'
        ]
        dest: 'build/js/app/app-bundled.js'
      ]
      options:
        banner: '\n(function() {\n\n'
        footer: '\n})();\n\n'
    )

    gruntConfig.configureTask(
      'watch', 'angular'

      files: [
        'client/app.coffee'
      ]
      tasks: [
        'build:angular', 'build:shrub'
      ]
      options: livereload: true
    )

    # Build the list of third-party Angular modules to be injected as
    # dependencies of the Angular application.
    gruntConfig.registerTask 'shrubAngularPackageDependencies:angular', ->

      pkgman = require 'pkgman'

      # #### Invoke hook `shrubAngularPackageDependencies`.
      dependencies = []
      for dependenciesList in pkgman.invokeFlat 'shrubAngularPackageDependencies'
        dependencies.push.apply dependencies, dependenciesList

      js = 'var packageDependencies = [];\n\n'
      js += "packageDependencies.push('#{
        dependencies.join "');\npackageDependencies.push('"
      }');\n" if dependencies.length > 0

      grunt.file.write 'build/js/app/app-dependencies.js', js

    gruntConfig.registerTask 'build:angular', [
      'newer:coffee:angular'
      'shrubAngularPackageDependencies:angular'
      'concat:angular'
    ]

    gruntConfig.registerTask 'build', ['build:angular']