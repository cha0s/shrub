
nconf = require 'nconf'
Middleware = (require 'middleware').Middleware
pkgman = require 'pkgman'

module.exports = class AbstractHttp

	constructor: (@_config) ->
		
		@_middleware = new Middleware()
		
	initialize: (fn) ->
	
		middleware = new Middleware()
		
		pkgman.invoke 'httpInitializer', (_, initializer) ->
			middleware.use initializer
		
		request = http: this
		response = null
		middleware.dispatch request, response, fn
		
	config: -> @_config
		
	port: -> @_config.port
		
	registerMiddleware: ->
		
		# TODO this will be package-based.
		for name in @_config.middleware
			middleware = (require "packages/express/middleware/#{name}").middleware this
			middleware = [middleware] unless Array.isArray middleware
			middleware.forEach (middleware) => @_middleware.use middleware
