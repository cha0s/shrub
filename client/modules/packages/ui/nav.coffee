
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
			
			scope.navClass = if attr['uiNav'] then attr['uiNav'] else 'ui-nav'
		
			scope.links = nav.links
			scope.user = user.instance()
			
			scope.$watch(
				-> title.page()
				-> scope.pageTitle = title.page()
			)
			
			(navActiveLinks = ->
			
				path = $location.path()
				for link in scope.links()
				
					regexp = new RegExp "^#{link.pattern}$", ['i']
					link.active = if regexp.test path then 'active'
					
			)()
			
# Make sure we set active the first time, since angular-strap won't be ready.

			scope.$watch(
				-> scope.links()
				navActiveLinks	
			)

			scope.$watch(
				-> $location.path()
				navActiveLinks	
			)
			
		template: """

<nav class="navbar navbar-default" role="navigation">
	<div class="container-fluid">
		
		<div class="navbar-header">
			<button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".{{navClass}}">
				<span class="sr-only">Toggle navigation</span>
				<span class="icon-bar"></span>
				<span class="icon-bar"></span>
				<span class="icon-bar"></span>
			</button>

			<a class="navbar-brand" href="#"><span data-ng-bind="pageTitle"></span></a>
			
		</div>
		
		<div class="navbar-collapse collapse" data-ng-class="navClass">
			<p class="navbar-text">
				<span class="identity">
					You are <span class="username" data-ng-bind="user.name"></span>
				</span>
			</p>
			<ul class="nav navbar-nav navbar-right">
				<li data-ng-class="link.active" data-match-route="{{link.pattern}}" data-ng-repeat="link in links()">
					<a data-ng-href="{{link.href}}" data-ng-bind="link.name"></a>
				</li>
			</ul>
		</div>
		
	</div>
</nav>

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
