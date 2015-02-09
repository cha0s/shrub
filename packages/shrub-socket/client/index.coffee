
# # Socket
#
# Provide an Angular service wrapping a real-time socket.

config = require 'config'

exports.pkgmanRegister = (registrar) ->

  # ## Implements hook `service`
  registrar.registerHook 'service', ->

    {Manager} = require config.get 'packageConfig:shrub-socket:manager:module'
    Manager
