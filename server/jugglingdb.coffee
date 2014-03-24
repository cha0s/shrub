
# # JugglingDB

nconf = require 'nconf'

# `TODO`: This module currently immediately attempts to gather package models
# and create the schema: it should provide a function to lookup that
# information instead of doing it all at require time.
module.exports = require('schema-client').define(
	require "jugglingdb-redis"
	apiRoot: nconf.get 'apiRoot'
	cryptoKey: nconf.get 'cryptoKey'
)
