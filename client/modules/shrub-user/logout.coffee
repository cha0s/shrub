
# # User logout

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `route`
	registrar.registerHook 'route', ->
		
		path: 'user/logout'
		
		controller: [
			'$location', 'shrub-user'
			($location, {isLoggedIn, logout}) ->
				return $location.path '/' unless isLoggedIn()
				
				logout().then -> $location.path '/'
	
		]
