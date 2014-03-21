
{EventEmitter} = require 'events'
pkgman = require 'pkgman'

middleware = require 'middleware'

{defaultLogger} = require 'logging'

module.exports = class AbstractSocketFactory extends EventEmitter
	
	constructor: (@_config) ->
		super
	
	class @AuthorizationFailure extends Error
		constructor: (@message) ->
	
	loadMiddleware: ->
		
		defaultLogger.info 'BEGIN loading socket authorization middleware:'
		
		@_authorizationMiddleware = middleware.fromHook(
			'socketAuthorizationMiddleware'
			@_config.authorizationMiddleware
		)
		
		defaultLogger.info 'END loading socket authorization middleware.'

		defaultLogger.info 'BEGIN loading socket middleware:'
		
		@_requestMiddleware = middleware.fromHook(
			'socketRequestMiddleware'
			@_config.requestMiddleware
		)
		
		defaultLogger.info 'END loading socket middleware.'

	for method in [
		'listen', 'socketsInChannel'
	]
		@::[method] = -> throw new ReferenceError(
			"AbstractSocket#{method} is a pure virtual method!"
		)
