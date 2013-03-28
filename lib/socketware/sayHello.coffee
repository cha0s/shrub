
module.exports = (req, report) ->
	
# Wait 2 seconds and say hi, telling the user their session ID.
	
	setTimeout(
		->
			req.injectSession (session) ->
				req.socket.emit(
					'notifications'
					notifications: [
						text: "Welcome! Your session ID is #{session.id}"
					]
				)
		2000
	)
