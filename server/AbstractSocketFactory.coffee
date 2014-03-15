
{EventEmitter} = require 'events'
pkgman = require 'pkgman'
winston = require 'winston'

middleware = require 'middleware'

module.exports = class AbstractSocketFactory extends EventEmitter
	
	constructor: (@_config) ->
		super
	
	loadMiddleware: ->
		
		winston.info 'BEGIN loading socket middleware:'
		
		@_middleware = middleware.fromHook(
			'socketMiddleware'
			@_config.middleware
		)
		
		winston.info 'END loading socket middleware.'

	for method in [
		'listen', 'socketsInChannel'
	]
		@::[method] = -> throw new ReferenceError(
			"AbstractSocket#{method} is a pure virtual method!"
		)
