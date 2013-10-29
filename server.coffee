
nconf = require 'nconf'
path = require 'path'
winston = require 'winston'

# Log errors to the console, the rest will go into logs/shrub.log by default.
winston.remove winston.transports.Console
winston.add winston.transports.Console, level: 'error'
winston.add winston.transports.File, filename: 'logs/shrub.log'

nconf.argv().env().file path.join __dirname, 'config', 'settings.json'

# A bunch of temporary bootstrappy nonsense that will (mostly) be abstracted
# away.
nconf.defaults
	
	cryptoKey: 'WeDemandShrubbery'
	
	path: __dirname
	
	
	# Server-side render context configuration.
	contexts:
		
		# Should we render on the server-side?
		render: true
		
		# Context timeout in milliseconds.
		timeout: 1000 * 60 * 5
	
	services:
	
		http:
			
			port: 4201
			express:
				sessions:
					db: 'redis'
					key: 'connect.sid'
					cookie:
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

http = new (require './server/http/express') path.join __dirname, 'app'

socket = new (require './server/socket/socketIo') http

http.listen -> console.info "Shrub server listening on port #{http.port()}..."
