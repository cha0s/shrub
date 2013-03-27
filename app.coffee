
###
 # Module dependencies.
###

express = require 'express'
fs = require 'fs'
http = require 'http'
net = require 'net'
path = require 'path'

app = express()

# Read the settings file. Any configuration value specified will be accessible
# at app.get/set
filename = path.join __dirname, 'config', 'settings.json'
if fs.existsSync filename
	settings = fs.readFileSync filename
else
	throw new Error "Copy config/settings-default.json to config/settings.json"
app.set key, value for key, value of JSON.parse settings.toString()

# Set up cookie/session handling.
redis = require path.join 'connect-redis', 'node_modules', 'redis'
redisClient = redis.createClient()
RedisStore = require('connect-redis') express

sessionOptions = app.get 'sessionOptions'
sessionOptions.cookieParser = express.cookieParser sessionOptions.secret

redisSessionOptions = app.get 'redisSessionOptions'
redisSessionOptions.client = redisClient
sessionOptions.store = new RedisStore redisSessionOptions

app.configure ->

	app.set 'views', path.join __dirname, 'app'
	app.set 'view engine', 'html'
	app.engine 'html', require('hbs').__express
	app.use express.favicon()
	
	# Log to a file.
	logStream = fs.createWriteStream(
		path.join 'logs', 'express'
		flags: 'a'
	)
	app.use express.logger stream: logStream
	
	app.use sessionOptions.cookieParser
	app.use express.session sessionOptions
	
	app.use express.bodyParser()
	app.use express.methodOverride()
	app.use app.router
	app.use express.static path.join __dirname, 'app'

app.configure 'development', ->
	
	app.use express.errorHandler()

# Include our scripts, images and CSS based on what mode the server is running
# in.
require(path.join __dirname, 'lib', 'assets') app	

# Spin up the server.
server = http.createServer app

# Set up the socket.io server.
io = require('socket.io').listen server

SocketHandling = require path.join __dirname, 'lib', 'SocketManager'
socketHandling = new SocketHandling()

# The main entry point.
for resourcePath in [
	'/'
	
# For testacular.
	'/app/index.html'
]
	
	app.get resourcePath, (req, res) ->

		Config = {}
		
# Are we in debug mode?
		Config.debugging = if 'debug' is (process.env.NODE_ENV ? 'debug')
			true
		else
			false
		
		res.render 'index',
			
			Config: JSON.stringify Config

# Configure sockets based on the environment we're running on.
socketHandling.configure io, redis

# Handle socket authorization, which will tie the socket to a session.
socketHandling.authorize io, sessionOptions

# Route socket traffic.
routesDirectory = path.join __dirname, 'lib', 'SocketMiddleware'
for middleware in [
	'sayHello'
]
	socketHandling.use require path.join routesDirectory, middleware

socketHandling.route io, sessionOptions

# This is it! Get ready to listen to the interwebs.
server.listen app.get('port'), ->
	
	console.log "Express server listening on port #{app.get 'port'}"
