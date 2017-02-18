# # Express - static files
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubHttpMiddleware`.
  #
  # Serve static files.
  registrar.registerHook 'shrubHttpMiddleware', (http) ->

    express = require 'express'

    config = require 'config'

    label: 'Serve static files'
    middleware: [
      express.static config.get 'packageConfig:shrub-http:path'
    ]