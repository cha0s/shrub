
_ = require 'lodash'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		->

			scope: field: '=?'

			link: (scope, element) ->

				scope.$watchCollection(
					-> scope.field.checkboxes
					->

						for checkbox in scope.field.checkboxes
							checkbox.childName ?= checkbox.name
							checkbox.name = "#{
								scope.field.name
							}[#{
								checkbox.childName
							}]"
							checkbox.type = 'checkbox'

						return

				)

				scope.$watchCollection(
					-> scope.field.checkboxes.map (checkbox) -> checkbox.value
					->

						scope.field.value = {}

						for checkbox in scope.field.checkboxes
							scope.field.value[checkbox.childName] = checkbox.value

						return

				)

			template: '''

<div class="checkboxes">

	<label
		data-ng-bind="field.label"
	></label>

	<ul>

		<li
			data-ng-class="{first: $first}"
			data-ng-repeat="checkbox in field.checkboxes"
			data-shrub-form-widget-checkbox
			data-field="checkbox"
		></li>

	</ul>

</div>

'''

	]

	assignToElement = (element, value) ->

		for k, v of value

			element.find('.checkbox input[name"' + k + '"]').prop 'checked', true

	# ## Implements hook `formWidgets`
	registrar.registerHook 'formWidgets', ->

		widgets = []

		widgets.push

			type: 'checkboxes'
			assignToElement: assignToElement
			directive: 'shrub-form-widget-checkboxes'

		widgets

