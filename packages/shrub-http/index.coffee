# # HTTP
#
# Manage HTTP connections.
config = require 'config'
pkgman = require 'pkgman'

debug = require('debug') 'shrub:http'

httpManager = null

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubCoreBootstrapMiddleware`.
  registrar.registerHook 'shrubCoreBootstrapMiddleware', ->

    label: 'Bootstrap HTTP server'
    middleware: [

      (next) ->

        {manager, port} = config.get 'packageConfig:shrub-http'

        {Manager} = require manager.module

        # Spin up the HTTP server, and initialize it.
        httpManager = new Manager()

        # Spawn workers into a cluster.
        httpManager.cluster()

        # Trust prox(y|ies).
        httpManager.trustProxy(
          config.get 'packageConfig:shrub-core:trustedProxies'
        )

        httpManager.initialize().then(->

          debug "Shrub HTTP server up and running on port #{port}!"
          next()

        ).catch next

    ]

  # #### Implements hook `shrubHttpMiddleware`.
  registrar.registerHook 'shrubHttpMiddleware', (http) ->

    label: 'Finalize HTTP request'
    middleware: [

      (req, res, next) ->

        if req.delivery?

          res.send req.delivery

        else

          res.status 501
          res.end '<h1>501 Internal Server Error</h1>'

    ]

  # #### Implements hook `shrubConfigServer`.
  registrar.registerHook 'shrubConfigServer', ->

    manager:

      # Module implementing the socket manager.
      module: 'shrub-http-express'

    middleware: [
      'shrub-http-express/static'
      'shrub-core'
      'shrub-socket/factory'
      'shrub-http-express/session'
      'shrub-passport'
      'shrub-http-express/logger'
      'shrub-villiany'
      'shrub-form'
      'shrub-http-express/routes'
      'shrub-config'
      'shrub-skin/path'
      'shrub-assets'
      'shrub-skin/render'
      'shrub-http-express/errors'
    ]

    path: "#{config.get 'path'}/app"

    port: 4201

exports.manager = -> httpManager