
nconf = require 'nconf'
pkgman = require 'pkgman'
winston = require 'winston'

middleware = require 'middleware'

module.exports = class AbstractHttp

	constructor: (@_config) ->
		
		@_middleware = null
		
	initialize: (fn) ->
	
		middleware = new middleware.Middleware()
		
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
		
		winston.info 'BEGIN loading HTTP middleware:'
		
		@_middleware = middleware.fromHook(
			'httpMiddleware'
			@_config.middleware
			(_, spec) =>
				spec = spec this
				winston.info spec.label
				spec
		)
		
		winston.info 'END loading HTTP middleware.'
