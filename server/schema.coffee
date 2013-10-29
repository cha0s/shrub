
nconf = require 'nconf'

exports.define = (adapter, options = {}) ->
	
	options.cryptoKey = nconf.get 'cryptoKey'
	
	schema = require('schema').define(
		require('jugglingdb').Schema
		adapter
		options
	)
	
	# Hax.
	schema.adapter.own = schema.adapter.all
	
	schema
