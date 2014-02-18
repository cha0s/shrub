
express = require 'express'

module.exports.middleware = (http) ->

	express.static http.path()
