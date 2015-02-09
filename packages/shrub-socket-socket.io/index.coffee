
# # Socket.IO
#
# SocketManager implementation using [Socket.IO](http://socket.io/).

exports.pkgmanRegister = (registrar) ->

  # ## Implements hook `assetMiddleware`
  registrar.registerHook 'assetMiddleware', ->

    config = require 'config'

    label: 'Socket.IO'
    middleware: [

      (assets, next) ->

        if 'production' is config.get 'NODE_ENV'

          assets.scripts.push '/lib/socket.io/socket.io.min.js'

        else

          assets.scripts.push '/lib/socket.io/socket.io.js'

        next()

    ]

  # ## Implements hook `gruntConfig`
  registrar.registerHook 'gruntConfig', (gruntConfig) ->

    gruntConfig.copy ?= {}
    gruntConfig.watch ?= {}

    gruntConfig.configureTask 'copy', 'shrub-socket.io', files: [
      src: '**/*'
      dest: 'app'
      expand: true
      cwd: "#{__dirname}/app"
    ]

    gruntConfig.configureTask(
      'watch', 'shrub-socket.io'

      files: [
        "#{__dirname}/app/**/*"
      ]
      tasks: 'build:shrub-socket.io'
    )

    gruntConfig.registerTask 'build:shrub-socket.io', [
      'newer:copy:shrub-socket.io'
    ]

    gruntConfig.registerTask 'build', ['build:shrub-socket.io']

exports.Manager = require './manager'
