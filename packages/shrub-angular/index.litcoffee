# Angular

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `gruntConfig`.

      registrar.registerHook 'gruntConfig', (gruntConfig, grunt) ->

        gruntConfig.configureTask(
          'coffee', 'angular'

          files: [
            src: [
              'client/app.litcoffee'
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
            'client/app.litcoffee'
          ]
          tasks: [
            'build:angular', 'build:shrub'
          ]
          options: livereload: true
        )

        gruntConfig.registerTask 'angularPackageDependencies:angular', ->

          pkgman = require 'pkgman'

          dependencies = []

#### Invoke hook `angularPackageDependencies`.

          for dependenciesList in pkgman.invokeFlat 'angularPackageDependencies'
            dependencies.push.apply dependencies, dependenciesList

          js = '\nvar packageDependencies = [];\n\n\n'
          js += "packageDependencies.push('#{dependencies.join "');\npackageDependencies.push('"}');\n" if dependencies.length > 0

          grunt.file.write 'build/js/app/app-dependencies.js', js

        gruntConfig.registerTask 'build:angular', [
          'newer:coffee:angular'
          'angularPackageDependencies:angular'
          'concat:angular'
        ]

        gruntConfig.registerTask 'build', ['build:angular']
