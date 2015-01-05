
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		
		->
			
			directive = {}
			
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
	data-parent-name="parentName"
></ul>

"""

			directive
			
	]
