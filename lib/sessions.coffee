
express = require 'express'
path = require 'path'

module.exports = new class

	initialize: (app) ->
	
		redis = app.get 'redis'
		redis.module = require path.join 'connect-redis', 'node_modules', 'redis'
		RedisStore = require('connect-redis') express
	
		sessions = app.get 'sessions'
		sessions.cookieParser = express.cookieParser sessions.secret
		sessions.store = new RedisStore client: redis.module.createClient()
	
	middleware: (app) ->
		
		sessions = app.get 'sessions'
		app.use sessions.cookieParser
		app.use express.session sessions
