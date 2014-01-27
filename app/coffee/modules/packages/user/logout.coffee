
exports.$route =
	
	controller: [
		'$location', '$q', 'user'
		($location, $q, user) ->

			user.isLoggedIn (isLoggedIn) ->
				
				(if isLoggedIn then user.logout() else $q.when()).finally ->
					$location.path '/'
			
	]
	
	template: '-'

exports.$endpoint = (req, fn) ->
	
	{models: User: User} = require 'server/jugglingdb'

	req.logout()
	fn()
