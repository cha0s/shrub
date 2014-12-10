
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		
		->
			
			directive = {}
			
			directive.candidateKeys = [
				'parentName'
			]
			
			directive.link = (scope) ->
					
				scope.item ?= {}
				scope.parentName ?= ''
				
				scope.item.submenu ?= null
				scope.item.class ?= ''
				scope.item.href ?= '#'
				scope.item.text ?= ''
				
			directive.scope =
				
				item: '=?'
				parentName: '=?'
				
			directive.template = """

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
	data-ng-if="item.submenu"
	
	data-shrub-ui-menu
	data-items="item.submenu.items"
	data-name="item.submenu.name"

	data-class="children"
></div>

"""

			directive
			
	]
