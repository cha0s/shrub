
nconf = require 'nconf'
net = require 'net'
pkgman = require 'pkgman'
repl = require 'repl'

exports.$initialized = ->

	replServer = null

	# Feed all the goodies into a REPL for ultimate awesome.
	replServer = net.createServer (socket) ->
		
		s = repl.start(
			prompt: "reddichat> "
			input: socket
			output: socket
		)
		
		s.context.config = nconf
		
		pkgman.invoke 'replContext', (_, spec) -> spec s.context
		
		s.on 'exit', -> socket.end()
		
	replServer.listen "#{__dirname}/socket"

	process.on 'SIGINT', ->
		replServer.close()
		process.exit 1
