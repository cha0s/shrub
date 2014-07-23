
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		
		->
			
			link: (scope, lElement) ->
					
				scope.item ?= {}
				
				scope.item.children ?= []
				scope.item.class ?= ''
				scope.item.href ?= '#'
				scope.item.text ?= ''
				
			scope:
				
				item: '=?'
				
			template: """

<a
	class="menu-item"
	data-ng-class="item.class"
	data-ng-href="{{item.href}}"
>
	
	<span
		data-ng-bind="item.text"
	></span>
	
</a>

<div
	data-ng-if="item.children.length"
	
	data-shrub-ui-menu
	data-items="item.children"

	data-class="children"
></div>

"""
			
	]
