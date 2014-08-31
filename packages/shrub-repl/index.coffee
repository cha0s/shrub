
# # REPL
# 
# Runs a REPL and allows packages to add values to its context.

CoffeeScript = require 'coffee-script'
fs = require 'fs'
net = require 'net'
replServer = require 'repl'

config = require 'config'
pkgman = require 'pkgman'

# The socket server.
server = null

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `packageSettings`
	registrar.registerHook 'packageSettings', ->
		
		# The prompt display for REPL clients.
		prompt: 'shrub> '
		
		# The location of the socket.
		socket: "#{__dirname}/socket"
		
		# Use a CoffeeScript REPL?
		useCoffee: true
		
	# ## Implements hook `processExit`
	registrar.registerHook 'processExit', -> server?.close()
	
	# ## Implements hook `ready`
	registrar.registerHook 'ready', ->
		
		settings = config.get 'packageSettings:shrub-repl'
		
		server = net.createServer (socket) ->
			
			settings = config.get 'packageSettings:shrub-repl'
		
			# Invoke hook `replContext`.
			# Allow packages to add values to the REPL's context.
			pkgman.invoke 'replContext', context = {}
			
			opts =
				prompt: settings.prompt
				input: socket
				output: socket
				ignoreUndefined: true
			
			# Allow settings to define whether the REPL runs CoffeeScript.
			if settings.useCoffee
				
				opts.prompt = "#{settings.prompt}(coffee) "
				
				# } Define our own eval function, using CoffeeScript.
				opts.eval = (cmd, context, filename, callback) ->
					
					try
					
						callback null, CoffeeScript.eval(
							cmd
							sandbox: context
							filename: filename
						)
						
					catch error
						
						callback error
			
			# Spin up the server, inject the values from `replContext`, and prepare
			# for later cleanup.
			repl = replServer.start opts
			repl.context[key] = value for key, value of context
			repl.on 'exit', -> socket.end()
		
		# } Try to be tidy about things.	
		fs.unlink settings.socket, -> server.listen settings.socket