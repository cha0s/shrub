
# Body contents.

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		
		->
			
			directive = {}
			
			directive.template = """

<div class="container">
	<div data-shrub-ui-nav></div>
	
	<div data-shrub-ui-notifications></div>
	
	<div class="main" data-ng-view></div>
</div>

"""

			directive
		
	]
