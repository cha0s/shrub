
nconf = require 'nconf'
pkgman = require 'pkgman'
Promise = require 'bluebird'
winston = require 'winston'

middleware = require 'middleware'

module.exports = class AbstractHttp

	constructor: (@_config) ->
		
		@_middleware = null
		
	initialize: (fn) ->
	
		middleware = new middleware.Middleware()
		for _, initializer of pkgman.invoke 'httpInitializer'
			middleware.use initializer
		
		request = http: this
		response = null
		middleware.dispatch request, response, (error) =>
			return fn error if error?
			
			@listen (error) =>
				return fn error if error?
				
				promises = for _, promise of pkgman.invoke(
					'httpListening', this
				)
					promise
					
				
				Promise.all(promises).then(
					-> fn()
					(error) -> fn error
				)
		
	config: -> @_config
		
	port: -> @_config.port
		
	registerMiddleware: ->
		
		winston.info 'BEGIN loading HTTP middleware:'
		
		@_middleware = middleware.fromHook(
			'httpMiddleware'
			@_config.middleware
			this
		)
		
		winston.info 'END loading HTTP middleware.'
