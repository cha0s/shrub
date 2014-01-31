
_ = require 'underscore'
nconf = require 'nconf'
path = require 'path'
walk = require 'walk'
Q = require 'q'

Middleware = (require 'middleware').Middleware

module.exports = class Rpc
	
	constructor: (@http) ->
		
		@_config = nconf.get 'services:socket'
		
		# Middleware.
		@_socketMiddleware = new Middleware
		for name in @_config.middleware
			list = (require "./middleware/#{name}").middleware()
			list = [list] unless Array.isArray list
			@_socketMiddleware.use middleware for middleware in list
