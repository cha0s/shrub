
nconf = require 'nconf'
winston = require 'winston'

# Log errors to the console, the rest will go into logs/shrub.log by default.
winston.remove winston.transports.Console
winston.add winston.transports.Console, level: 'error'
winston.add winston.transports.File, filename: 'logs/shrub.log'

nconf.argv().env().file "#{__dirname}/config/settings.json"

# A bunch of temporary bootstrappy nonsense that will (mostly) be abstracted
# away.
nconf.defaults
	
	cryptoKey: 'WeDemandShrubbery'
	
	path: __dirname
	
	# Server-side render context configuration.
	contexts:
		
		# Should we render on the server-side?
		render: not process.env['E2E']?
		
		# Context timeout in milliseconds.
		timeout: 1000 * 60 * 5
	
	packageList: [
		'core'
		'comm'
		'example'
		'socket.io'
		'ui'
		'user'
	]
	
	services:
	
		http:
			
			path: "#{__dirname}/app"
			
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
				'passport'
				'jugglingdb'
				'favicon'
				'logger'
				'static'
				'locals'
				'angular'
				'errors'
			]
						
		socket:
			
			socketIo:
				
				db: 'redis'

			middleware: [
				'session'
				'passport'
				'rpc'
			]

module.exports = nconf
