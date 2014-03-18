
pkgman = require 'pkgman'

exports.$auditKeys = (req) -> ["ip:#{req.ip}"]

exports.$httpMiddleware = (http) ->
	
	label: 'Normalize request variables'
	middleware: [
	
		(req, res, next) ->
			
			req.ip = req.headers['x-forwarded-for'] ? req.connection.remoteAddress
			
			next()
		
	]

exports.$replContext = (context) ->

	context.clearCaches = ->
		
		pkgman.invoke 'clearCaches'
		
exports.$socketMiddleware = ->
	
	label: 'Normalize request variables'
	middleware: [
	
		(req, res, next) ->
			
			req.ip = req.headers['x-forwarded-for'] ? req.address.address

			next()
			
	]
