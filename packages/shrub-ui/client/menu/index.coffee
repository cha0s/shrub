
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		
		'$compile'
		($compile) ->
			
			compile: (cElement, attrs) ->
				
				contents = cElement.contents().remove()
			
				(scope, lElement) ->
					
					scope.class ?= ''
					scope.items ?= []
				
					if contents?

						compiled = $compile contents
						lElement.append compiled scope, angular.identity
					
			scope:
				
				class: '=?'
				items: '=?'
				
			template: """

<ul
	class="menu"
	data-ng-class="class"
>
	<li
		data-ng-repeat="item in items"

		data-shrub-ui-menu-item
		data-item="item"
	></li>
</ul>

"""
			
	]

	registrar.recur [
		'item'
	]
