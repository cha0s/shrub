
exports.$endpoint = (req, fn) ->
	
	switch req.body.method
		
		when 'local'
			
			(req.passport.authenticate 'local', (error, user, info) ->
				return fn attempted: error.message if error?
				return fn code: 420 unless user
				
				req.login user, (error) ->
					return fn attempted: error.message if error?
					fn null, user
			
			) req, res = {}
