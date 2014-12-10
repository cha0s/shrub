
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		
		'$compile'
		($compile) ->
			
			directive = {}
			
			# Prevent infinite recursion when compiling nested menus.
			directive.compile = (cElement) ->
			
				contents = cElement.contents().remove()
				
				(scope, lElement, attrs) ->
					
					directive.link scope, lElement, attrs
			
					compiled = $compile contents
					lElement.append compiled scope, angular.identity
					
			directive.link = (scope, element, attrs) ->
					
				scope.class ?= ''
				scope.items ?= []
				scope.name ?= ''
				
			directive.scope =
				
				class: '=?'
				items: '=?'
				name: '=?'
				
			directive.template = """

<ul
	class="menu"
	data-ng-class="class"
>
	<li
		data-ng-repeat="item in items"

		data-shrub-ui-menu-item
		data-item="item"
		data-parent-name="name"
	></li>
</ul>

"""
			
			directive
			
	]

	registrar.recur [
		'item'
	]
