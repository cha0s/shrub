
nconf = require 'nconf'

exports.define = (adapter) ->
	
	schema = require('schema-client').define(
		require "jugglingdb-#{adapter}"
		apiRoot: nconf.get 'apiRoot'
		cryptoKey: nconf.get 'cryptoKey'
	)
	
	schema
