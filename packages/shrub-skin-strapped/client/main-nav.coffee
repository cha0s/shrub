
# # Navigation

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		'shrub-ui/window-title', 'shrub-user'
		(windowTitle, user) ->
		
			link: (scope, elm, attr) ->
				
				scope.menu = 

					name: 'main-nav'
					attributes:
						class: ['nav', 'navbar-nav', 'navbar-right']
						id: 'main-nav'
					items: [
						path: 'home'
						label: 'Home'
					,
						path: 'about'
						label: 'About'
					,
						path: 'user/register'
						label: 'Sign up'
					,
						path: 'user/login'
						label: 'Sign in'
					,
						path: 'user/logout'
						label: 'Sign out'
					]
				
				scope.user = user.instance()
				
				scope.$watch(
					-> windowTitle.page()
					-> scope.pageTitle = windowTitle.page()
				)
				
			template: """
	
<nav class="navbar navbar-default" role="navigation">
	<div class="container-fluid">
	
		<div class="navbar-header">
			<button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".shrub-skin-strapped-ui-nav">
				<span class="sr-only">Toggle navigation</span>
				<span class="icon-bar"></span>
				<span class="icon-bar"></span>
				<span class="icon-bar"></span>
			</button>
			<a class="navbar-brand" href="#"><span data-ng-bind="pageTitle"></span></a>
		</div>
		
		<div class="navbar-collapse collapse shrub-skin-strapped-ui-nav">

			<p class="navbar-text navbar-right identity-wrapper">
				<span class="identity">
					You are <span class="username" data-ng-bind="user.name"></span>
				</span>
			</p>
			
			<div
				data-shrub-ui-menu
				data-menu="menu"
			></div>
		</div>
	</div>
</nav>

"""
			
	]
