
$module.controller 'user/logout', [
	'$location', 'user'
	($location, user) ->
		
		user.logout().finally -> $location.path '/'
		
]
