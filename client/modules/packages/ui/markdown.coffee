
marked = require 'marked'

exports.$filter = ->

	(input, sanitize = true) -> marked input, sanitize: sanitize
