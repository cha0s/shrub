
nconf = require 'nconf'

pkgman = require 'pkgman'

exports.$auditKeys = (req) ->
	
	ip: req.normalizedIp

resolvedAddress = (trustedProxies, address, forwardedFor) ->
	return address unless forwardedFor?
	return address if trustedProxies.length is 0
	
	split = forwardedFor.split /\s*, */
	return split[0] if -1 isnt trustedProxies.indexOf address
	
	address
		
exports.$httpMiddleware = (http) ->
	
	label: 'Normalize request variables'
	middleware: [
	
		(req, res, next) ->
			
			req.normalizedIp = resolvedAddress(
				nconf.get 'packageSettings:core:trustedProxies'
				req.connection.remoteAddress
				req.headers['x-forwarded-for']
			)
				
			next()
		
	]

exports.$replContext = (context) ->

	context.clearCaches = ->
		
		pkgman.invoke 'clearCaches'

exports.$settings = ->

	trustedProxies: []
		
exports.$socketAuthorizationMiddleware = ->
	
	label: 'Normalize request variables'
	middleware: [
	
		(req, res, next) ->
			
			req.normalizedIp = resolvedAddress(
				nconf.get 'packageSettings:core:trustedProxies'
				req.address.address
				req.headers['x-forwarded-for']
			)
				
			next()
			
	]
