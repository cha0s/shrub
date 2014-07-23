
# # Socket
# 
# Provide an Angular service wrapping a real-time socket.

config = require 'config'

exports.pkgmanRegister = (registrar) ->
	
	# ## Implements hook `service`
	registrar.registerHook(
		'service'
		-> require config.get 'packageConfig:shrub-socket:manager:module'
	)
