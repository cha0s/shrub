
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `controller`
	registrar.registerHook 'controller', -> [

		class ListItemController

			link: (scope, element, attr) ->

				scope.$watch(
					-> scope.item?.markup
					->

						for child in element.children()

							# Child list?
							$child = angular.element child
							continue if $child.attr('data-shrub-ui-list')?

							$child.remove()

						element.prepend scope.item.markup if scope.item?.markup

				)

	]



	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [

		->

			directive = {}

			directive.bindToController = true

			directive.candidateKeys = [
				'ancestorPath'
			]

			directive.scope =

				item: '='
				ancestorPath: '=?'

			directive.template = '''

<ul
	data-ng-if="item.list"
	data-shrub-ui-list
	data-shrub-ui-attributes="item.list.attributes"
	data-list="item.list"
	data-parent-ancestor-path="ancestorPath"
></ul>

'''

			directive

	]
