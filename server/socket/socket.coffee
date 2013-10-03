
_ = require 'underscore'
nconf = require 'nconf'
path = require 'path'
walk = require 'walk'
Q = require 'q'

module.exports = class Rpc
	
	constructor: (@http) ->
		
		@_config = nconf.get 'services:socket'
		
		# Middleware.
		list = for name in @_config.middleware
			list = (require "./middleware/#{name}").middleware()
			list = [list] unless Array.isArray list
			middleware for middleware in list
		list = (_.flatten list).reverse()
		
		@_middlewareRegistration = (req, res, next) ->
			
			dispatcher = next
			
			for middleware in list
				previous = dispatcher
				dispatcher = do (middleware, previous) ->
					-> middleware req, res, previous
					
			dispatcher()
				
	registerMiddleware: (req, res) ->
	
		@_middlewareRegistration req, res, ->
			
			req.socket.emit 'initialized'
	
