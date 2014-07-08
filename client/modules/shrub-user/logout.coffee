
# # User logout

# ## Implements hook `route`
exports.$route = ->
	
	controller: [
		'$location', 'shrub-user'
		($location, {isLoggedIn, logout}) ->
			return $location.path '/' unless isLoggedIn()
			
			logout().then -> $location.path '/'

	]
