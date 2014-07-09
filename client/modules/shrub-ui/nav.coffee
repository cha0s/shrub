
# # Navigation

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		'$location', 'shrub-ui/nav', 'shrub-ui/title', 'shrub-user'
		($location, {links}, {page}, {instance}) ->
		
			link: (scope, elm, attr) ->
				
				# `TODO`: This whole thing needs to be overhauled.
				scope.links = links
				scope.navClass = if attr['uiNav'] then attr['uiNav'] else 'ui-nav'
				scope.user = instance()
				
				scope.$watch(
					-> page()
					-> scope.pageTitle = page()
				)
				
				(navActiveLinks = ->
				
					path = $location.path()
					for link in scope.links()
					
						regexp = new RegExp "^#{link.pattern}$", ['i']
						link.active = if regexp.test path then 'active'
						
				)()
				
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
			<p class="navbar-text navbar-right identity-wrapper">
				<span class="identity">
					You are <span class="username" data-ng-bind="user.name"></span>
				</span>
			</p>
			<ul class="nav navbar-nav navbar-right">
				<li data-ng-class="link.active" data-match-route="{{link.pattern}}" data-ng-repeat="link in links()">
					<a target="{{link.target}}" data-ng-href="{{link.href}}" data-ng-bind="link.name"></a>
				</li>
			</ul>
		</div>
		
	</div>
</nav>

"""
			
	]
	
	# ## Implements hook `service`
	# 
	# This API allows you to dynamically change the navigation links.
	# `TODO`: Overhaul this.
	registrar.registerHook 'service', -> [
		->
			
			service = {}
			
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
			
			service.links = -> _links
			service.setLinks = (links) -> _links = links
			
			service
			
	]
