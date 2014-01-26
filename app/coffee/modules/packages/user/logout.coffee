
exports.$route =
	
	controller: [
		'$location', 'user'
		($location, user) ->
			
			user.logout().finally -> $location.path '/'
			
	]
	
	template: '-'

exports.$endpoint = (req, fn) ->
	
	{models: User: User} = require 'server/jugglingdb'

	req.logout()
	fn()
