
fs = require 'fs'
nconf = require 'nconf'
net = require 'net'
pkgman = require 'pkgman'
replServer = require 'repl'

server = null

exports.$initialized = ->

	filename = "#{__dirname}/socket"
	
	# Feed all the goodies into a REPL for ultimate awesome.
	server = net.createServer (socket) ->
		
		pkgman.invoke 'replContext', context = {}
		
		repl = replServer.start(
			prompt: "shrub> "
			input: socket
			output: socket
		)
		
		repl.context[key] = value for key, value of context
		
		repl.on 'exit', -> socket.end()
		
	fs.unlink filename, -> server.listen filename
	
exports.$processExit = -> server.close()
	