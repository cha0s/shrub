
_ = require 'lodash'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		->

			scope: field: '=?'

			link: (scope, element) ->

				scope.$watch 'field', (field) ->

					element.find('input').attr 'data-ng-model', field.value

			template: """

<div class="radio">

	<label>

		<input
			name="{{field.name}}"
			type="radio"

			data-ng-value="field.selectedValue"
		>

		{{field.label}}

	</label>

</div>

"""

	]

	assignToElement = (element, value) ->

		element.prop 'checked', true

	# ## Implements hook `formWidgets`
	registrar.registerHook 'formWidgets', ->

		widgets = []

		widgets.push

			type: 'radio'
			assignToElement: assignToElement
			directive: 'shrub-form-widget-radio'

		widgets
