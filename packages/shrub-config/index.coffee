
# # Configuration
# 
# Client-side configuration.


_ = require 'underscore'
Promise = require 'bluebird'
url = require 'url'

config = require 'config'
pkgman = require 'pkgman'

{Config} = require 'client/modules/config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `httpMiddleware`
	registrar.registerHook 'httpMiddleware', (http) ->
		
		label: 'Serve package configuration'
		middleware: [
	
			# Serve the configuration module.
			(req, res, next) ->
				
				# Only if the path matches.
				return next() unless req.url is '/js/config.js'
				
				# Invoke hook `config`.
				# Allows packages to specify configuration that will be sent to
				# the client. Implementations may return an object, or a promise
				# that resolves to an object.
				subconfigs = pkgman.invoke 'config', req
					
				Promise.all(
					
					promise for path, promise of subconfigs
					
				).then((fulfilledSubconfigs) ->
	
					# } Merge ALL the configs.
					config_ = new Config()
					
					# } Package-independent...
					config_.set 'packageList', config.get 'packageList'
					
					index = 0
					for path of subconfigs
						
						subconfig = fulfilledSubconfigs[index++]
						for key, value of subconfig
							config_.set "packageConfig:#{
								path.replace /\//g, ':'
							}:#{
								key
							}", value
					
					# } Format the configuration to look nice.
					prettyPrintConfig = ->
						stringified = JSON.stringify config_, null, '  '
						[first, rest...] = stringified.split '\n'
						([first].concat rest.map (line) -> '    ' + line).join '\n'
					
					# Emit the configuration module.
					res.setHeader 'Content-Type', 'text/javascript'
					
					res.send """
angular.module(
  'shrub.config', ['shrub.require']
)

  .config(['shrub-requireProvider', function(requireProvider) {

    requireProvider.require('config').from(#{prettyPrintConfig()});

  }]);
	"""
					
				).catch next
				
		]
