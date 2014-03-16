
fs = require 'fs'
nconf = require 'nconf'
net = require 'net'
pkgman = require 'pkgman'
repl = require 'repl'

server = null

exports.$initialized = ->

	filename = "#{__dirname}/socket"
	
	# Feed all the goodies into a REPL for ultimate awesome.
	server = net.createServer (socket) ->
		
		repl = repl.start(
			prompt: "shrub> "
			input: socket
			output: socket
		)
		
		pkgman.invoke 'replContext', repl.context
		
		repl.on 'exit', -> socket.end()
		
	fs.unlink filename, -> server.listen filename
	
exports.$processExit = -> server.close()
	