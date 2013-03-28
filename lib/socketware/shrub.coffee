
module.exports = (req, report) ->
	
	app = req.app
	sessions = app.get 'sessions'
	session = req.socket.handshake.session

# Inject a session into a callback chain, loading and touching it.
	req.injectSession = (callback) ->
		args = (arguments[i] for i in [1...arguments.length])
		sessions.store.load session.id, (error, session) ->
			throw error if error?
			session.touch()
			session.save (error) ->
				throw error if error?
				args[args.length] = session
				callback.apply callback, args
	

# Join a channel for the session.
	req.injectSession (session) -> req.socket.join session.id
	
	