
nconf = require 'nconf'

exports.define = (adapter) ->
	
	require('schema-client').define(
		require "jugglingdb-#{adapter}"
		apiRoot: nconf.get 'apiRoot'
		cryptoKey: nconf.get 'cryptoKey'
	)
