
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `controller`
	registrar.registerHook 'controller', -> [

		class ListItemController
			
			link: (scope, element, attrs) ->
				
				scope.$watch(
					-> scope.parentName
					-> element.addClass "child-of-#{scope.parentName}"
				)
			
	]
	
	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		
		->
			
			directive = {}
			
			directive.bindToController = true
			
			directive.candidateKeys = [
				'parentName'
			]
			
			directive.scope =
				
				item: '='
				parentName: '=?'
				
			directive.template = """

<div
	data-ng-bind-html="item.markup"
></div>

<ul
	data-ng-if="item.list"
	data-shrub-ui-list
	data-list="item.list"
></ul>

"""

			directive
			
	]
