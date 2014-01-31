
exports.$httpInitializer = (req, res, next) ->
	
	socket = new (require './socketIo') req.http
	
	next()

