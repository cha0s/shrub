
ConnectSession = require('express').session.Session
nconf = require 'nconf'
utils = require 'express/node_modules/connect/lib/utils'

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
