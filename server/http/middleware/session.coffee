
express = require 'express'
winston = require 'winston'

module.exports.middleware = (http) -> [
	http.cookieParser()
	express.session key: http.sessionKey(), store: http.sessionStore()
]
