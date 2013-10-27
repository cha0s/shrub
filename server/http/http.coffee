
nconf = require 'nconf'

module.exports = class Http

	constructor: ->
		
		@_config = nconf.get 'services:http'
		
	config: -> @_config
		
	port: -> @_config.port
		
	registerMiddleware: ->
		
		for name in @_config.middleware
			middleware = (require "./middleware/#{name}").middleware this
			middleware = [middleware] unless Array.isArray middleware
			middleware.forEach (middleware) => @use middleware
