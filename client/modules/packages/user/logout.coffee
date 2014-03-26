
# # User logout

# ## Implements hook `route`
exports.$route = ->
	
	controller: [
		'$location', 'user'
		($location, {isLoggedIn, logout}) ->
			return $location.path '/' unless isLoggedIn()
			
			logout().then -> $location.path '/'

	]
