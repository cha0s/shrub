
# # Socket factory

nconf = require 'nconf'

# The socket factory.
socketFactory = null

# ## Implements hook `httpInitializer`
exports.$httpInitializer = -> (req, res, next) ->
	
	config = nconf.get 'packageSettings:socket'
	
	# Spin up the socket server, and have it listen on the HTTP server.
	socketFactory = new (require config.module) config
	socketFactory.loadMiddleware()
	socketFactory.listen req.http
	
	next()
	
# ## Implements hook `httpMiddleware`
exports.$httpMiddleware = (http) ->
	
	label: 'Register socket factory'
	middleware : [
		(req, res, next) ->
			
			req.socketFactory = socketFactory
			
			next()
	]

# ## Implements hook `replContext`
exports.$replContext = (context) ->
	
	# Provide the socketFactory to REPL.
	context.socketFactory = socketFactory

# ## Implements hook `socketRequestMiddleware`
exports.$socketRequestMiddleware = ->
	
	label: 'Register socket factory'
	middleware : [
		(req, res, next) ->
			
			req.socketFactory = socketFactory
			
			next()
	]

