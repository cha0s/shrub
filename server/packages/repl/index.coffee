
CoffeeScript = require 'coffee-script'
fs = require 'fs'
nconf = require 'nconf'
net = require 'net'
replServer = require 'repl'

pkgman = require 'pkgman'

server = null

exports.$initialized = ->
	
	settings = nconf.get 'packageSettings:repl'
	
	# Feed all the goodies into a REPL for ultimate awesome.
	server = net.createServer (socket) ->
		
		settings = nconf.get 'packageSettings:repl'
	
		pkgman.invoke 'replContext', context = {}
		
		opts =
			prompt: 'shrub> '
			input: socket
			output: socket
			ignoreUndefined: true
		
		if settings.useCoffee
			
			opts.prompt = 'shrub (coffee)> '
			
			opts.eval = (cmd, context, filename, callback) ->
				
				try
				
					callback null, CoffeeScript.eval(
						cmd
						sandbox: context
						filename: filename
					)
					
				catch error
					
					callback error
		
		repl = replServer.start opts
		
		repl.context[key] = value for key, value of context
		
		repl.on 'exit', -> socket.end()
		
	fs.unlink settings.socket, -> server.listen settings.socket
	
exports.$processExit = -> server?.close()
	
exports.$settings = ->

	socket: "#{__dirname}/socket"
	useCoffee: true
