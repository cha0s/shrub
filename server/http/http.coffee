
nconf = require 'nconf'
Middleware = (require 'middleware').Middleware

module.exports = class Http

	constructor: ->
		
		@_config = nconf.get 'services:http'
		@_middleware = new Middleware()
		
	config: -> @_config
		
	port: -> @_config.port
		
	registerMiddleware: ->
		
		for name in @_config.middleware
			middleware = (require "./middleware/#{name}").middleware this
			middleware = [middleware] unless Array.isArray middleware
			middleware.forEach (middleware) => @_middleware.use middleware
