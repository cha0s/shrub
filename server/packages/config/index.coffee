
# # Configuration
# 
# Client-side configuration.

url = require 'url'

_ = require 'underscore'
nconf = require 'nconf'
Promise = require 'bluebird'

pkgman = require 'pkgman'

{Config} = require 'config'

# ## Implements hook `config`
exports.$config = (req) ->
	
	# The URL that the site was accessed at.
	# 
	# } `TODO`: Renamed to host.
	baseUrl: "//#{req.headers.host}"
	
	# Is the server running in test mode?
	testMode: if (req.nconf.get 'E2E')? then 'e2e' else false
	
	# Debug mode if we're not running in production.
	# 
	# } `TODO`: Remove this, and implement a client logging system.
	debugging: 'production' isnt req.nconf.get 'NODE_ENV'
	
	# The list of enabled packages.
	packageList: req.nconf.get 'packageList'

# ## Implements hook `httpMiddleware`
exports.$httpMiddleware = (http) ->
	
	label: 'Serve package configuration'
	middleware: [

		# Store nconf in the request.
		(req, res, next) ->
			
			# } `TODO`: Should probably just remove this and `require 'nconf'`.
			req.nconf = nconf
			
			next()
		
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
					([first].concat rest.map (line) -> '  ' + line).join '\n'
				
				# Emit the configuration module.
				res.setHeader 'Content-Type', 'text/javascript'
				
				# } `TODO`: This shouldn't be a module, we can do this better.
				res.send """
angular.module('shrub.config', []).provider('config', function() {

  var __slice = [].slice;
  
  return new ((#{Config.toString()})())(#{prettyPrintConfig()});

});
"""
				
			).catch next
			
	]

# ## Implements hook `replContext`
# 
# } `TODO`: Should probably just remove this and `require 'nconf'`.
exports.$replContext = (context) -> context.config = nconf
