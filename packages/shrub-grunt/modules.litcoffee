# Grunt build process - Modules

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `gruntConfig`.

      registrar.registerHook 'gruntConfig', (gruntConfig) ->

        gruntConfig.configureTask 'coffee', 'modules', files: [
          cwd: 'client'
          src: [
            'packages.litcoffee'
            'require.litcoffee'
            'modules/**/*.{coffee,litcoffee}'
          ]
          dest: 'build/js/app'
          expand: true
          ext: '.js'
        ,
          src: [
            '{custom,packages}/*/client/**/*.{coffee,litcoffee}'
          ]
          dest: 'build/js/app'
          expand: true
          ext: '.js'
        ]

        gruntConfig.configureTask 'concat', 'modules', files: [
          src: [
            'build/js/app/{modules,packages,require}.js'
          ]
          dest: 'build/js/app/modules.js'
        ]

        gruntConfig.configureTask 'copy', 'modules', files: [
          expand: true
          cwd: 'client/modules'
          src: ['**/*.js']
          dest: 'build/js/app/modules'
        ,
          expand: true
          src: ['{custom,packages}/*/client/**/*.js']
          dest: 'build/js/app'
        ]

        gruntConfig.configureTask(
          'watch', 'modules'

          files: [
            'client/{packages,require}.litcoffee'
            'client/modules/**/*.{coffee,litcoffee}'
            '{custom,packages}/*/client/**/*.{coffee,litcoffee}'
          ]
          tasks: [
            'build:modules', 'build:shrub'
          ]
          options: livereload: true
        )

        gruntConfig.configureTask(
          'wrap', 'modules'

          files: [
            src: [
              'build/js/app/modules/**/*.js'
              'build/js/app/{custom,packages}/*/client/**/*.js'
            ]
            dest: 'build/js/app/modules.js'
          ]
          options:
            indent: '  '
            wrapper: (filepath) ->

              path = require 'path'

              matches = filepath.match /build\/js\/app\/([^/]+)\/(.*)/

              switch matches[1]

                when 'modules'

                  moduleName = matches[2]

                when 'custom', 'packages'

                  parts = matches[2].split '/'
                  parts.splice 1, 1
                  moduleName = parts.join '/'

              dirname = path.dirname moduleName
              if dirname is '.' then dirname = '' else dirname += '/'

              extname = path.extname moduleName

              moduleName = "#{dirname}#{path.basename moduleName, extname}"

              if moduleName?
                [
                  "requires_['#{moduleName}'] = function(module, exports, require, __dirname, __filename) {\n\n"
                  '\n};\n'
                ]
              else
                ['', '']

        )

        gruntConfig.configureTask(
          'wrap', 'modulesAll'

          files: ['build/js/app/modules.js'].map (file) -> src: file, dest: file
          options:
            indent: '  '
            wrapper: [
              '(function() {\n\n  var requires_ = {};\n\n'
              '\n\n})();\n\n'
            ]

        )

        gruntConfig.registerTask 'build:modules', [
          'newer:coffee:modules'
          'newer:copy:modules'
          'wrap:modules'
          'concat:modules'
          'newer:wrap:modulesAll'
        ]

        gruntConfig.registerTask 'build', ['build:modules']
