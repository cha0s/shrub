
# # Configuration
# 
# Client-side configuration.

url = require 'url'

_ = require 'underscore'
nconf = require 'nconf'
Promise = require 'bluebird'

pkgman = require 'pkgman'

# ## Implements hook `config`
exports.$config = (req) ->
	
	# The URL that the site was accessed at.
	hostname: "//#{req.headers.host}"
	
	# Is the server running in test mode?
	testMode: if (nconf.get 'E2E')? then 'e2e' else false
	
	# Execution environment, `production`, or...
	environment: nconf.get 'NODE_ENV'
	
	# The list of enabled packages.
	packageList: nconf.get 'packageList'

# ## Implements hook `httpMiddleware`
exports.$httpMiddleware = (http) ->
	
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
			Promise.all(
				pkgman.invokeFlat 'config', req
				
			).then((subconfigs) ->

				# } Merge ALL the configs.
				config = {}
				_.extend config, subconfig for subconfig in subconfigs				
			
				# } Format the configuration to look nice.
				prettyPrintConfig = ->
					stringified = JSON.stringify config, null, '  '
					[first, rest...] = stringified.split '\n'
					([first].concat rest.map (line) -> '    ' + line).join '\n'
				
				# Emit the configuration module.
				res.setHeader 'Content-Type', 'text/javascript'
				
				res.send """
angular.module(
  'shrub.config', ['shrub.require']
)

  .config(['requireProvider', function(requireProvider) {

    requireProvider.require('config').from(#{prettyPrintConfig()});

  }]);
"""
				
			).catch next
			
	]
