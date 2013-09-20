module.exports = (req, data) ->
	
	req.socket.emit(
		'notifications'
		notifications: [
			text: "Welcome! Your session ID is #{req.session.id}"
		]
	)
