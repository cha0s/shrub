
ConnectSession = require('express').session.Session
utils = require 'express/node_modules/connect/lib/utils'

exports.define = (adapter, options = {}) ->
	
	schema = require('schema').define(
		require('jugglingdb').Schema
		adapter
		options
	)
	
	# Hax.
	schema.adapter.own = schema.adapter.all
	
	schema
