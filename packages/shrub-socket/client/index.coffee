
# # Socket
# 
# Provide an Angular service wrapping a real-time socket.

config = require 'config'

exports.pkgmanRegister = (registrar) ->
	
	{Manager} = require config.get 'packageConfig:shrub-socket:manager:module'
	
	# ## Implements hook `service`
	registrar.registerHook 'service', -> Manager
