
nconf = require 'nconf'

socketFactory = null

exports.$httpInitializer = (req, res, next) ->
	
	config = nconf.get 'services:socket'
	
	socketFactory = new (require config.module) config
	
	socketFactory.loadMiddleware()
	
	socketFactory.listen req.http
	
	next()
	
exports.$httpMiddleware = (http) ->
	
	label: 'Register socket factory'
	middleware : [
		(req, res, next) ->
			
			req.socketFactory = socketFactory
			
			next()
	]

exports.$socketMiddleware = ->
	
	label: 'Register socket factory'
	middleware : [
		(req, res, next) ->
			
			req.socketFactory = socketFactory
			
			next()
	]

