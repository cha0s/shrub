
fs = require 'fs'
nconf = require 'nconf'
net = require 'net'
pkgman = require 'pkgman'
repl = require 'repl'

exports.$initialized = ->

	filename = "#{__dirname}/socket"
	replServer = null
	
	# Feed all the goodies into a REPL for ultimate awesome.
	replServer = net.createServer (socket) ->
		
		s = repl.start(
			prompt: "shrub> "
			input: socket
			output: socket
		)
		
		s.context.config = nconf
		
		pkgman.invoke 'replContext', (_, spec) -> spec s.context
		
		s.on 'exit', -> socket.end()
		
	fs.unlink filename, -> replServer.listen filename
