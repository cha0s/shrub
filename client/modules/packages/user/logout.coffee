
exports.$route = ->
	
	controller: [
		'$location', '$q', 'user'
		($location, $q, user) ->
			return $location.path '/' unless user.isLoggedIn()
			
			user.logout().then -> $location.path '/'

	]
