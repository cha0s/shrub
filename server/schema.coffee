
# # JugglingDB

nconf = require 'nconf'

module.exports = require('client/modules/schema').define(
	require "jugglingdb-redis"
	apiRoot: nconf.get 'apiRoot'
	cryptoKey: nconf.get 'cryptoKey'
)
