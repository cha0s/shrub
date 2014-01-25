
module.exports =

	$route:
		
		controller: [
			'$location', 'user'
			($location, user) ->
				
				user.logout().finally -> $location.path '/'
				
		]
		
		template: '-'

	$endpoint: (req, data, fn) ->
		
		{models: User: User} = require 'server/jugglingdb'
	
		req.logout()
		fn()
