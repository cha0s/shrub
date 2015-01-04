
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `controller`
	registrar.registerHook 'controller', -> [

		class ListController
		
			link: (scope, element, attrs) ->
				
				scope.$watch(
					-> scope.list.name
					-> element.addClass scope.list.name
				)
				
	]
	
	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		
		'$compile', '$timeout'
		($compile, $timeout) ->
			
			directive = {}
			
			directive.bindToController = true
			
			directive.candidateKeys = [
				'name'
			]
			
			# Prevent infinite recursion when compiling nested lists.
			directive.compile = (cElement) ->
			
				contents = cElement.contents().remove()
				
				(scope, lElement, attrs, controller) ->
					
					compiled = $compile contents
					lElement.append compiled scope
					
					directive.link arguments...

			directive.scope =
				
				list: '='
				
			directive.template = """

<li
	data-ng-repeat="item in list.items"

	data-shrub-ui-list-item
	data-item="item"
	data-parent-name="list.name"
></li>

"""
			
			directive
			
	]

	registrar.recur [
		'item'
	]
