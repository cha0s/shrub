
{EventEmitter} = require 'events'
pkgman = require 'pkgman'
winston = require 'winston'

middleware = require 'middleware'

module.exports = class AbstractSocketFactory extends EventEmitter
	
	constructor: (@_config) ->
		super
	
	class @AuthorizationFailure extends Error
		constructor: (@message) ->
	
	loadMiddleware: ->
		
		winston.info 'BEGIN loading socket authorization middleware:'
		
		@_authorizationMiddleware = middleware.fromHook(
			'socketAuthorizationMiddleware'
			@_config.authorizationMiddleware
		)
		
		winston.info 'END loading socket authorization middleware.'

		winston.info 'BEGIN loading socket middleware:'
		
		@_requestMiddleware = middleware.fromHook(
			'socketRequestMiddleware'
			@_config.requestMiddleware
		)
		
		winston.info 'END loading socket middleware.'

	for method in [
		'listen', 'socketsInChannel'
	]
		@::[method] = -> throw new ReferenceError(
			"AbstractSocket#{method} is a pure virtual method!"
		)
