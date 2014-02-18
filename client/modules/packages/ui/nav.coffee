
exports.$appRun = [
	'ui/nav'
	(nav) ->

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
]

exports.$directive = [
	'$location', 'ui/nav', 'socket', 'ui/title', 'user'
	($location, nav, socket, title, user) ->
	
		link: (scope, elm, attr) ->
		
			scope.links = nav.links
			scope.user = user.load()
			
			scope.$watch(
				-> title.page()
				-> scope.title = title.page()
			)
			
# Make sure we set active the first time, since angular-strap won't be ready.

			scope.$watch(
				-> scope.links()
				->
					path = $location.path()
					for link in scope.links()
					
						regexp = new RegExp "^#{link.pattern}$", ['i']
						link.active = if regexp.test path then 'active'
					
			)
			
		template: """

<div class="navbar" data-bs-navbar>
	<div class="navbar-inner">
		
		<h1 class="title muted">
			<span data-ng-bind="title"></span>
		</h1>
		<span class="identity">
			You are
			<span class="username" data-ng-bind="user.name"></span>.
		</span>
		
		<a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
			<span class="icon-bar"></span>
			<span class="icon-bar"></span>
			<span class="icon-bar"></span>
		</a>
		
		<div class="nav-collapse collapse">
			<ul class="nav pull-right">
				<li data-ng-class="link.active" data-match-route="{{link.pattern}}" data-ng-repeat="link in links()">
					<a data-ng-href="{{link.href}}" data-ng-bind="link.name"></a>
				</li>
			</ul>
		</div>
		
	</div>
</div>

"""
		
]

exports.$service = [
	->
	
# This API allows you to dynamically change the navigation links.
		
		_links = []
		
# Get and set the navigation links. The links are objects structured like so:
# 
# * pattern: A string or regex containing the path to match to set this item
# active.
# * href: Target navigation path when this item is clicked.
# * name: Human readable name for the item.
# 
# e.g.
# 
#     item =
#         pattern: '/home'
#         href: '#/home'
#         name: 'Home'
		
		@links = -> _links
		@setLinks = (links) -> _links = links
		
		return
		
]
