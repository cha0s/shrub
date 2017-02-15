# Grunt build process - Build tests
```coffeescript
exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubGruntConfig`.
```coffeescript
  registrar.registerHook 'shrubGruntConfig', (gruntConfig) ->

    gruntConfig.configureTask 'coffee', 'testsE2e', files: [
      src: [
        'client/modules/**/test-e2e.coffee'
        '{custom,packages}/*/client/**/test-e2e.coffee'
      ]
      dest: 'build/js/tests'
      expand: true
      ext: '.js'
    ]

    gruntConfig.configureTask 'coffee', 'testsE2eExtensions', files: [
      src: [
        'test/e2e/extensions/**/*.coffee'
      ]
      dest: 'build/js/tests'
      expand: true
      ext: '.js'
    ]

    gruntConfig.configureTask 'coffee', 'testsUnit', files: [
      src: [
        'client/modules/**/test-unit.coffee'
        '{custom,packages}/*/client/**/test-unit.coffee'
      ]
      dest: 'build/js/tests'
      expand: true
      ext: '.js'
    ]

    gruntConfig.configureTask 'concat', 'testsE2e', files: [
      src: [
        'build/js/tests/**/test-e2e.js'
      ]
      dest: 'build/js/tests/test/scenarios-raw.js'
    ]

    gruntConfig.configureTask 'concat', 'testsE2eExtensions', files: [
      src: [
        'build/js/tests/test/e2e/extensions/**/*.js'
      ]
      dest: 'test/e2e/extensions.js'
    ]

    gruntConfig.configureTask 'concat', 'testsUnit', files: [
      src: [
        'build/js/tests/**/test-unit.js'
      ]
      dest: 'build/js/tests/test/tests-raw.js'
    ]

    gruntConfig.configureTask 'copy', 'testsE2e', files: [
      src: [
        'client/modules/**/test-e2e.js'
        '{custom,packages}/*/client/**/test-e2e.js'
      ]
      dest: 'build/js/tests'
    ]

    gruntConfig.configureTask 'copy', 'testsUnit', files: [
      src: [
        'client/modules/**/test-unit.js'
        '{custom,packages}/*/client/**/test-unit.js'
      ]
      dest: 'build/js/tests'
    ]

    gruntConfig.configureTask(
      'watch', 'testsE2e'

      files: [
        'client/modules/**/test-e2e.coffee'
        '{custom,packages}/*/client/**/test-e2e.coffee'
      ]
      tasks: ['build:testsE2e']
    )

    gruntConfig.configureTask(
      'watch', 'testsE2eExtensions'

      files: [
        'test/e2e/extensions/**/*.coffee'
      ]
      tasks: ['build:testsE2eExtensions']
    )

    gruntConfig.configureTask(
      'watch', 'testsUnit'

      files: [
        'client/modules/**/test-unit.coffee'
        '{custom,packages}/*/client/**/test-unit.coffee'
      ]
      tasks: ['build:testsUnit']
    )

    gruntConfig.configureTask(
      'wrap', 'testsE2e'

      files: [
        src: [
          'build/js/tests/test/scenarios-raw.js'
        ]
        dest: 'test/e2e/scenarios.js'
      ]
      options:
        indent: '  '
        wrapper: [
          "describe('#{gruntConfig.pkg.name}', function() {\n\n\n"
          '\n});\n'
        ]
    )

    gruntConfig.configureTask(
      'wrap', 'testsUnit'

      files: [
        src: [
          'build/js/tests/test/tests-raw.js'
        ]
        dest: 'test/unit/tests.js'
      ]
      options:
        indent: '  '
        wrapper: [
          "describe('#{gruntConfig.pkg.name}', function() {\n\n  beforeEach(function() {\n    module('shrub.core');\n  });\n\n"
          '\n});\n'
        ]
    )

    gruntConfig.registerTask 'build:testsE2e', [
      'newer:coffee:testsE2e'
      'newer:copy:testsE2e'
      'concat:testsE2e'
      'wrap:testsE2e'
    ]

    gruntConfig.registerTask 'build:testsE2eExtensions', [
      'newer:coffee:testsE2eExtensions'
      'concat:testsE2eExtensions'
    ]

    gruntConfig.registerTask 'build:testsUnit', [
      'newer:coffee:testsUnit'
      'newer:copy:testsUnit'
      'concat:testsUnit'
      'wrap:testsUnit'
    ]

    gruntConfig.registerTask 'build:tests', [
      'build:testsE2e'
      'build:testsE2eExtensions'
      'build:testsUnit'
    ]

    gruntConfig.registerTask 'build', ['build:tests']
```
#### Implements hook `shrubGruntConfigAlter`.
```coffeescript
  registrar.registerHook 'shrubGruntConfigAlter', (gruntConfig) ->

    ignoreFiles = (array, directory) ->
      array.push "!#{directory}/**/#{spec}" for spec in [
        'test-{e2e,unit}.coffee'
        '*.spec.coffee'
      ]

    coffeeConfig = gruntConfig.taskConfiguration 'coffee', 'modules'
    ignoreFiles coffeeConfig.files[0].src, 'modules'
    ignoreFiles coffeeConfig.files[1].src, 'custom/*/client'
    ignoreFiles coffeeConfig.files[1].src, 'packages/*/client'

    watchConfig = gruntConfig.taskConfiguration 'watch', 'modules'
    ignoreFiles watchConfig.files, directory for directory in [
      'client/modules'
      '{custom,packages}/*/client'
    ]
```
