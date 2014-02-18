
nconf = require 'nconf'
pkgman = require 'pkgman'
winston = require 'winston'

Middleware = (require 'middleware').Middleware

module.exports = class AbstractSocket
	
	constructor: (@http) ->
		
		@_config = nconf.get 'services:socket'
		
		socketMiddleware = {}
		pkgman.invoke 'socketMiddleware', (path, spec) =>
			socketMiddleware[path] = spec @http
			
		winston.info 'BEGIN loading socket middleware:'
		
		@_middleware = new Middleware
		for path in @_config.middleware
			return unless (list = socketMiddleware[path].middleware)?
			list = [list] unless Array.isArray list
			
			winston.info socketMiddleware[path].label
			
			@_middleware.use middleware for middleware in list

		winston.info 'END loading socket middleware:'
		
