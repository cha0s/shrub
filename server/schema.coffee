
# # JugglingDB

config = require 'config'

module.exports = require('client/modules/schema').define(
	require "jugglingdb-redis"
)
