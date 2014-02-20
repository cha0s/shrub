
nconf = require 'nconf'
winston = require 'winston'

# Log errors to the console, the rest will go into logs/shrub.log by default.
winston.remove winston.transports.Console
winston.add winston.transports.Console, level: 'silly'
winston.add winston.transports.File, filename: 'logs/shrub.log'

nconf.argv().env().file "../config/settings.json"

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
		'errors'
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
				'form'
				'session'
				'user'
				'schema'
				'logger'
				'files/static'
				'config'
				'assets'
				'angular'
				'errors'
			]
						
		socket:
			
			socketIo:
				
				db: 'redis'

			middleware: [
				'session'
				'user'
				'rpc'
			]

module.exports = nconf
