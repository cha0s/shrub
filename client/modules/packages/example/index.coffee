
exports.$appRun = [
	'ui/nav', 'ui/title'
	(nav, title) ->

		nav.setLinks [
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
		
		title.setSite 'Shrub'
]

exports[path] = require "packages/example/#{path}" for path in [
	'about', 'home'
]
