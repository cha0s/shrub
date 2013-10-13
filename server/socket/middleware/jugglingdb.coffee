
###

Socket middleware - [JugglingDB](https://github.com/1602/jugglingdb)

This middleware proxies database (specifically, adapter) commands from the
client to the server.

###

express = require 'express'

schema = require 'server/jugglingdb'

commands = require('jugglingdb-socket').commands

checkPermissions = (prop) ->

module.exports.middleware = -> [

	(req, res, next) ->

		# Register a socket listener for each adapter command.
		for prop in Object.keys commands
			do (prop) => req.socket.on "jugglingdb-#{prop}", (data, fn) ->
				
				# Look up the model.
				# TODO This is a nop, but will be used for access control.
				# TODO Restrict access to non-client models.
				model = schema.models[data.arguments[0]]
				
				# Patch the arguments to insert a callback function where the
				# adapter command is expecting it.
				callbackIndex = commands[prop]
				data.arguments[callbackIndex] = (error, result) ->
					
					# Return the result and/or any error.
					fn
						error: error.toString() if error?
						result: result 
				
				# Invoke the adapter method, converting the arguments object
				# to an array.
				schema.adapter[prop].apply(
					schema.adapter
					arg for i, arg of data.arguments
				)
				
		next()

]
