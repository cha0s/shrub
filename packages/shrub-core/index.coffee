
# # Core
# 
# Implements various core functionality.

config = require 'config'

pkgman = require 'pkgman'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `config`
	registrar.registerHook 'config', (req) ->
		
		# The URL that the site was accessed at.
		hostname: if req.headers?.host?
			"//#{req.headers.host}"
		else
			"//#{config.get 'packageSettings:shrub-core:siteHostname'}"
		
		# Is the server running in test mode?
		testMode: if (config.get 'E2E')? then 'e2e' else false
		
		# Execution environment, `production`, or...
		environment: config.get 'NODE_ENV'
		
		# The user-visible site name.
		siteName: config.get 'packageSettings:shrub-core:siteName'
	
	# ## Implements hook `fingerprint`
	registrar.registerHook 'fingerprint', (req) ->
		
		# } The IP address.
		ip: req?.normalizedIp
	
	# ## Implements hook `httpMiddleware`
	registrar.registerHook 'httpMiddleware', (http) ->
		
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
	registrar.registerHook 'packageSettings', ->
		
		# Middleware for server bootstrap phase.
		bootstrapMiddleware: [
			'shrub-orm'
			'shrub-http-express/session'
			'shrub-http'
			'shrub-rpc'
			'shrub-user/login'
			'shrub-user/logout'
			'shrub-angular'
			'shrub-ui/notifications'
			'shrub-nodemailer'
		]
	
		# Global site crypto key.
		cryptoKey: "***CHANGE THIS***"
		
		# The default hostname of this application. Includes port if any.
		siteHostname: 'localhost:4201'
		
		# The name of the site, used in various places.
		siteName: "Shrub example application"
		
		# A list of the IP addresses of trusted proxies between clients.
		trustedProxies: []
			
	# ## Implements hook `replContext`
	registrar.registerHook 'replContext', (context) ->
	
		# Provide `clearCaches()` to the REPL.
		context.clearCaches = ->
			
			pkgman.invoke 'clearCaches'
	
	# ## Implements hook `socketAuthorizationMiddleware`
	registrar.registerHook 'socketAuthorizationMiddleware', ->
		
		label: 'Normalize request variables'
		middleware: [
		
			# Normalize IP address.	
			(req, res, next) ->
				
				req.normalizedIp = resolvedAddress(
					config.get 'packageSettings:shrub-core:trustedProxies'
					req.socket.client.conn.remoteAddress
					req.headers['x-forwarded-for']
				)
					
				next()
				
		]
		
# Walk up the X-Forwarded-For header until we hit an untrusted address.
resolvedAddress = (trustedProxies, address, forwardedFor) ->
	return address unless forwardedFor?
	return address if trustedProxies.length is 0
	
	split = forwardedFor.split /\s*, */
	index = split.length - 1
	address = split[index--] while -1 isnt trustedProxies.indexOf address
		
	address
