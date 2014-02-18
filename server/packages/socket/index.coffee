
exports.$httpInitializer = (req, res, next) ->
	
	socket = new (require './SocketIo') req.http
	
	next()
