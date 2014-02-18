
nconf = require 'nconf'
Middleware = (require 'middleware').Middleware
pkgman = require 'pkgman'
winston = require 'winston'

module.exports = class AbstractHttp

	constructor: (@_config) ->
		
		@_middleware = new Middleware()
		
	initialize: (fn) ->
	
		middleware = new Middleware()
		
		pkgman.invoke 'httpInitializer', (_, initializer) ->
			middleware.use initializer
		
		request = http: this
		response = null
		middleware.dispatch request, response, (error) =>
			return fn error if error?
			
			@listen fn
		
	config: -> @_config
		
	port: -> @_config.port
		
	registerMiddleware: ->
		
		httpMiddleware = {}
		pkgman.invoke 'httpMiddleware', (path, spec) =>
			httpMiddleware[path] = spec this
			
		@_middleware = new Middleware
		
		winston.info 'BEGIN loading HTTP middleware:'
		
		for path in @_config.middleware
			return unless (list = httpMiddleware[path].middleware)?
			list = [list] unless Array.isArray list
			
			winston.info httpMiddleware[path].label
			
			@_middleware.use middleware for middleware in list
		
		winston.info 'END loading HTTP middleware.'
