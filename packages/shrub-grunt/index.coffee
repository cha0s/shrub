# # Grunt build process
config = require 'config'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubAssetsMiddleware`.
  registrar.registerHook 'shrubAssetsMiddleware', ->

    label: 'Livereload'
    middleware: [

      (assets, next) ->

        return next() if 'production' is config.get 'NODE_ENV'

        hostname = config.get 'packageConfig:shrub-core:siteHostname'
        [hostname] = hostname.split ':'
        assets.scripts.push "http://#{hostname}:35729/livereload.js"

        next()

    ]

  # #### Implements hook `shrubConfigClientAlter`.
  registrar.registerHook 'shrubConfigClientAlter', (req, config_) ->
    return unless req.grunt?

    config_.set 'packageConfig:shrub-socket', manager: module: 'shrub-socket/dummy'
    config_.set 'packageConfig:shrub-user', name: 'Anonymous'

  # #### Implements hook `shrubGruntConfig`.
  registrar.registerHook 'shrubGruntConfig', (gruntConfig, grunt) ->

    gruntConfig.configureTask 'clean', 'shrub', [
      'app'
      'build'
    ]

    gruntConfig.configureTask 'concat', 'shrub', files: [
      src: [
        'build/js/app/{app-bundled,modules}.js'
      ]
      dest: 'app/lib/shrub/shrub.js'
    ]

    gruntConfig.configureTask 'uglify', 'shrub', files: [
      src: [
        'app/lib/shrub/shrub.js'
      ]
      dest: 'app/lib/shrub/shrub.min.js'
    ]

    gruntConfig.registerTask 'executeFunction:shrub', ->
      done = @async()

      # Pass arguments to the child process.
      args = process.argv.slice 2

      # Pass the environment to the child process.
      options = env: process.env

      # Fork it.
      {fork} = require 'child_process'
      child = fork "#{__dirname}/../../server.coffee", args, options
      child.on 'close', (code) ->
        return done() if code is 0

        grunt.fail.fatal 'Server process failed', code

    gruntConfig.registerTask 'build:shrub', [
      'concat:shrub'
    ]

    gruntConfig.registerTask 'production:shrub', [
      'newer:uglify:shrub'
    ]

    gruntConfig.registerTask 'execute', [
      'buildOnce'
      'executeFunction:shrub'
    ]

    gruntConfig.loadNpmTasks [
      'grunt-browserify'
      'grunt-contrib-clean'
      'grunt-contrib-coffee'
      'grunt-contrib-concat'
      'grunt-contrib-copy'
      'grunt-contrib-uglify'
      'grunt-contrib-watch'
      'grunt-newer'
      'grunt-wrap'
    ]

  # #### Implements hook `shrubGruntConfigAlter`.
  registrar.registerHook 'shrubGruntConfigAlter', (gruntConfig) ->

    gruntConfig.registerTask 'build', [
      'build:shrub'
    ]

    gruntConfig.registerTask 'production', [
      'production:shrub'
    ]

  registrar.recur [
    'dox', 'lint', 'modules', 'tests'
  ]