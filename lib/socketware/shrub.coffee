
module.exports = (req, report) ->
	
	app = req.app
	sessions = app.get 'sessions'
	session = req.socket.handshake.session

	req.loadSession = (callback) ->
		console.log req.socket.handshake.session.id
		sessions.store.load session.id, (error, session) ->
			return callback error if error?
			callback null, session

# Inject a session into a callback chain, loading and touching it.
	req.injectSession = (callback) ->
		->
			args = (arguments[i] for i in [0...arguments.length])
			req.loadSession (error, session) ->
				throw error if error?
				session.touch()
				session.save (error) ->
					throw error if error?
					args[args.length] = session
					callback.apply callback, args
	
# Join a channel for the session.
	req.loadSession (error, session) ->
		throw error if error?
		
		req.socket.join session.id
	