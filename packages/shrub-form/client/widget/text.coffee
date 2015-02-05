
exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		->

			scope: field: '=?'

			link: (scope) ->

				scope.$watch 'field', (field) ->

					field.minLength ?= 0
					field.maxLength ?= Infinity
					field.pattern ?= /.*/
					field.value ?= ''

			template: '''

<div class="form-group">

	<label
		data-ng-bind="field.label"
	></label>

	<input
		class="form-control"
		name="{{field.name}}"
		type="{{field.type}}"

		data-ng-model="field.value"
		data-ng-required="field.required"
		data-ng-minlength="{{field.minlength}}"
		data-ng-maxlength="{{field.maxlength}}"
		data-ng-pattern="field.pattern"
		data-ng-trim="{{field.trim}}"
	>

</div>

'''

	]

	assignToElement = (element, value) -> element.val value

	# ## Implements hook `formWidgets`
	registrar.registerHook 'formWidgets', ->

		widgets = []

		widgets.push

			type: 'email'
			assignToElement: assignToElement
			directive: 'shrub-form-widget-text'

		widgets.push

			type: 'password'
			assignToElement: assignToElement
			directive: 'shrub-form-widget-text'

		widgets.push

			type: 'text'
			assignToElement: assignToElement
			directive: 'shrub-form-widget-text'

		widgets
