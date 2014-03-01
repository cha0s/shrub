
nconf = require 'nconf'
winston = require 'winston'

# Log errors to the console, the rest will go into logs/shrub.log by default.
winston.remove winston.transports.Console
winston.add winston.transports.Console, level: 'silly'
winston.add winston.transports.File, filename: 'logs/shrub.log'

nconf.argv().env().file "#{__dirname}/../config/settings.json"

# A bunch of temporary bootstrappy nonsense that will (mostly) be abstracted
# away.
nconf.defaults
	
	apiRoot: '/api'
	
	cryptoKey: 'WeDemandShrubbery'
	
	path: "#{__dirname}/.."
	
	# Server-side render context configuration.
	contexts:
		
		# Should we render on the server-side?
		render: not process.env['E2E']?
		
		# Context time-to-live in milliseconds.
		ttl: 1000 * 60 * 5
	
	packageList: [
		'angular'
		'assets'
		'config'
		'core'
		'example'
		'express'
		'files'
		'form'
		'logger'
		'rpc'
		'schema'
		'session'
		'socket'
		'ui'
		'user'
	]
	
	services:
	
		http:
			
			path: "#{__dirname}/../app"
			
			port: 4201
			
			package: 'express'
			
			express:
				
				sessions:
					
					db: 'redis'
					
					key: 'connect.sid'
					
					cookie:
						
						cryptoKey: 'CookiesAreDelicious'
				
						maxAge: 1209600000
						
			middleware: [
				'socket/factory'
				'form'
				'express/session'
				'user'
				'express/logger'
				'express/routes'
				'express/static'
				'config'
				'assets'
				'angular'
				'express/errors'
			]
						
		socket:
			
			module: 'packages/socket/SocketIo'
			
			middleware: [
				'socket/factory'
				'session'
				'user'
				'rpc'
			]

			options:
			
				store: 'redis'

exports.config = nconf

exports.Config = -> class Config
	
	constructor: (@config) ->
	
	get: (key) ->
	
		current = @config
		current = current?[part] for part in key.split ':'
		current
	
	has: (key) ->
	
		current = @config
		for part in key.split ':'
			return false unless part of current
			current = current[part]
		
		return true
	
	set: (key, value) ->
		
		[parts..., last] = key.split ':'
		current = @config
		for part in parts
			current = (current[part] ?= {})
		
		current[last] = value
		
	$get: -> this
	