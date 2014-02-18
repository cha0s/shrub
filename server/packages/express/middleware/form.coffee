
express = require 'express'
winston = require 'winston'

module.exports.middleware = (http) -> [
	express.bodyParser()
	express.methodOverride()
]
