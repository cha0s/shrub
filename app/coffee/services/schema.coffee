
$module.service 'schema', [
	'require', 'socket'
	(require, socket) ->

		Schema = require('jugglingdb').Schema
		
		adapter = require 'jugglingdb-socket'
		require('schema').define(
			Schema
			schema = new Schema adapter, socket: socket
		)
		
		@models = schema.models
		
		return
		
]
