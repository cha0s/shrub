
# # Example!
# 
# Define some routes, set a nav, show some stuff off!

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `appRun`
	registrar.registerHook 'appRun', -> [
		'shrub-ui/nav'
		({setLinks}) ->
			
			setLinks [
				pattern: '/home', href: '/home', name: 'Home'
			,
				pattern: '/about', href: '/about', name: 'About'
			,
				pattern: '/user/register', href: '/user/register', name: 'Sign up'
			,
				pattern: '/user/login', href: '/user/login', name: 'Sign in'
			,
				pattern: '/user/logout', href: '/user/logout', name: 'Sign out'
			]
			
	]
	
	registrar.recur [
		'about', 'home'
	]