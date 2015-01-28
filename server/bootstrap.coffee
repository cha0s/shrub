
net = require 'net'

Promise = require 'bluebird'

{fork} = require 'child_process'

# Fork the process in order to inject require paths in if necessary.
exports.fork = ->

	# First make sure we have default require paths.
	if process.env.SHRUB_REQUIRE_PATH?

		SHRUB_REQUIRE_PATH = process.env.SHRUB_REQUIRE_PATH

	else

		SHRUB_REQUIRE_PATH = 'custom:.:packages:server:client/modules'

	# Fork the process to inject require paths into it.
	if process.env.SHRUB_FORKED?

		return null

	else

		# Pass arguments to the child process.
		args = process.argv.slice 2

		# Pass the environment to the child process.
		options = env: process.env

		# Integrate any NODE_PATH after the shrub require paths.
		if process.env.NODE_PATH?
			SHRUB_REQUIRE_PATH += ":#{process.env.NODE_PATH}"

		# Inject shrub require paths as the new NODE_PATH
		options.env.NODE_PATH = SHRUB_REQUIRE_PATH
		options.env.SHRUB_FORKED = true

		# Fork it
		fork process.argv[1], args, options

exports.openServerPort = ->

	new Promise (resolve, reject) ->

		server = net.createServer()

		server.listen 0, ->
			{port} = server.address()
			server.close -> resolve port

		server.on 'error', reject
