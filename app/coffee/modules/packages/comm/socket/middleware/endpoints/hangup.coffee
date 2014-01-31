
contexts = require 'server/contexts'

module.exports = (req, fn) ->
	
	return fn() unless (context = contexts.lookup req.session.id)?
	context.close fn
