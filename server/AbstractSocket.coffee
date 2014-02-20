
nconf = require 'nconf'
pkgman = require 'pkgman'
winston = require 'winston'

middleware = require 'middleware'

module.exports = class AbstractSocket
	
	constructor: (@http) ->
		
		@_config = nconf.get 'services:socket'
		
		winston.info 'BEGIN loading socket middleware:'
		
		@_middleware = middleware.fromHook(
			'socketMiddleware'
			@_config.middleware
			(_, spec) =>
				spec = spec @http
				winston.info spec.label
				spec
		)
		
		winston.info 'END loading socket middleware:'
		
