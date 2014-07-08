
# # Core
# 
# Implements various core functionality.

config = require 'config'

pkgman = require 'pkgman'

# ## Implements hook `config`
exports.$config = (req) ->
	
	siteName: config.get 'packageSettings:shrub-core:siteName'

# ## Implements hook `fingerprint`
exports.$fingerprint = (req) ->
	
	# } The IP address.
	ip: req?.normalizedIp

# Walk up the X-Forwarded-For header until we hit an untrusted address.
resolvedAddress = (trustedProxies, address, forwardedFor) ->
	return address unless forwardedFor?
	return address if trustedProxies.length is 0
	
	split = forwardedFor.split /\s*, */
	index = split.length - 1
	address = split[index--] while -1 isnt trustedProxies.indexOf address
		
	address
		
# ## Implements hook `httpMiddleware`
exports.$httpMiddleware = (http) ->
	
	label: 'Normalize request variables'
	middleware: [

		# Normalize IP address.	
		(req, res, next) ->
			
			req.normalizedIp = resolvedAddress(
				config.get 'packageSettings:shrub-core:trustedProxies'
				req.connection.remoteAddress
				req.headers['x-forwarded-for']
			)
				
			next()
		
	]

# ## Implements hook `packageSettings`
exports.$packageSettings = ->
	
	# Global site crypto key.
	cryptoKey: "***CHANGE THIS***"
	
	# The name of the site, used in various places.
	siteName: "Shrub example application"
	
	# A list of the IP addresses of trusted proxies between clients.
	trustedProxies: []
		
# ## Implements hook `replContext`
exports.$replContext = (context) ->

	# Provide `clearCaches()` to the REPL.
	context.clearCaches = ->
		
		pkgman.invoke 'clearCaches'

# ## Implements hook `socketAuthorizationMiddleware`
exports.$socketAuthorizationMiddleware = ->
	
	label: 'Normalize request variables'
	middleware: [
	
		# Normalize IP address.	
		(req, res, next) ->
			
			req.normalizedIp = resolvedAddress(
				config.get 'packageSettings:shrub-core:trustedProxies'
				req.address.address
				req.headers['x-forwarded-for']
			)
				
			next()
			
	]
