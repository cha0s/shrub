
###
 # Module dependencies.
###

express = require 'express'
fs = require 'fs'
http = require 'http'
net = require 'net'
path = require 'path'

app = express()

# Instantiate our services.
[config, logger, router, sessions, sockets, views] = for name in [
	'config', 'logger', 'router', 'sessions', 'sockets', 'views'
]
	require path.join __dirname, 'lib', name

# Initialize our services.
[
# Read config, 
	config
# set up sessions,
	sessions
# set up views engine.
	views
].forEach (module) -> module.initialize app

# Include our services' middleware.	
app.configure ->
	[
# Start logging,
		logger
# inject configuration,
		config
# create/load session,
		sessions
# handle routing.
		router
	].forEach (module) ->
		module.middleware app

# Let express handle routing errors.
app.configure 'development', -> app.use express.errorHandler()

# Include our scripts, images and CSS based on what mode the server is running
# in.
require(path.join __dirname, 'lib', 'assets') app	

# Spin up the server.
app.server = http.createServer app

# Initialize sockets.
sockets.initialize app

# Route incoming requests.
router.route app

# This is it! Get ready to listen to the interwebs.
app.server.listen app.get('port'), ->
	
	console.log "Shrub server listening on port #{app.get 'port'}"
