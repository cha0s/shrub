
express = require 'express'
path = require 'path'

module.exports.middleware = (http) ->

	express.favicon path.join http.path(), 'favicon.ico'
