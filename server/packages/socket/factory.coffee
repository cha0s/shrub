
# # Socket factory

nconf = require 'nconf'

# The socket factory.
socketFactory = null

# ## Implements hook `httpInitializing`
exports.$httpInitializing = (http) ->
	
	config = nconf.get 'packageSettings:socket'
	
	# Spin up the socket server, and have it listen on the HTTP server.
	socketFactory = new (require config.module) config
	socketFactory.loadMiddleware()
	socketFactory.listen http
	
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

# ## Implements hook `socketConnectionMiddleware`
exports.$socketConnectionMiddleware = ->
	
	label: 'Register socket factory'
	middleware : [
		(req, res, next) ->
			
			req.socketFactory = socketFactory
			
			next()
	]

