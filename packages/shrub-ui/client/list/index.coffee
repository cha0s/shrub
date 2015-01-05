
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `controller`
	registrar.registerHook 'controller', -> [

		class ListController
		
			link: (scope, element, attrs) ->
				
				scope.$watchGroup(
					[
						-> scope.list?.name
						-> scope.parentName
					]
					->
						
						parts = []
						
						parts.push scope.parentName if scope.parentName
						parts.push scope.list.name if scope.list?.name
						
						scope.fullParentName = parts.join '-'
				)
				
				scope.$watch(
					-> scope.list?.name
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
				'list.name'
				'fullParentName'
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
				parentName: '=?'
				
			directive.template = """

<li
	data-ng-repeat="item in list.items"

	data-shrub-ui-list-item
	data-item="item"
	data-parent-name="fullParentName"
></li>

"""
			
			directive
			
	]

	registrar.recur [
		'item'
	]
