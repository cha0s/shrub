
express = require 'express'
Schema = require('jugglingdb').Schema

adapter = require 'jugglingdb-socket'

models = require('schema').define(
	Schema
	schema = new Schema 'redis', {}
)

checkPermissions = (prop) ->

module.exports.middleware = -> [

	(req, res, next) ->

		for prop in Object.keys adapter.commands
			
			do (prop) =>
				
				req.socket.on "jugglingdb-#{prop}", (data, fn) ->
					
					model = models[data.arguments[0]]
					
					i = adapter.commands[prop]
					data.arguments[i] = (error, result) ->
						fn
							error: error.toString() if error?
							result: result 
					
					schema.adapter[prop].apply(
						schema.adapter
						arg for i, arg of data.arguments
					)
					
		next()

]
