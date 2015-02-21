# HTTP

Manage HTTP connections.

    config = require 'config'
    pkgman = require 'pkgman'

    debug = require('debug') 'shrub:http'

    httpManager = null

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `bootstrapMiddleware`.

      registrar.registerHook 'bootstrapMiddleware', ->

        label: 'Bootstrap HTTP server'
        middleware: [

          (next) ->

            {manager, port} = config.get 'packageSettings:shrub-http'

            {Manager} = require manager.module

Spin up the HTTP server, and initialize it.

            httpManager = new Manager()

Spawn workers into a cluster.

            httpManager.cluster()

            httpManager.initialize().then(->

              debug "Shrub HTTP server up and running on port #{port}!"
              next()

            ).catch next

        ]

#### Implements hook `httpMiddleware`.

      registrar.registerHook 'httpMiddleware', (http) ->

        label: 'Finalize HTTP request'
        middleware: [

          (req, res, next) ->

            if req.delivery?

              res.send req.delivery

            else

              res.status 501
              res.end '<h1>501 Internal Server Error</h1>'

        ]

#### Implements hook `packageSettings`.

      registrar.registerHook 'packageSettings', ->

        manager:

Module implementing the socket manager.

          module: 'shrub-http-express'

        middleware: [
          'shrub-core'
          'shrub-socket/factory'
          'shrub-http-express/session'
          'shrub-user'
          'shrub-audit'
          'shrub-http-express/logger'
          'shrub-villiany'
          'shrub-form'
          'shrub-http-express/routes'
          'shrub-http-express/static'
          'shrub-config'
          'shrub-skin/path'
          'shrub-assets'
          'shrub-skin/render'
          'shrub-angular'
          'shrub-http-express/errors'
        ]

        path: "#{config.get 'path'}/app"

        port: 4201

    exports.manager = -> httpManager
