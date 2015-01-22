
_ = require 'underscore'

exports.pkgmanRegister = (registrar) ->
	
	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		->
			
			scope: field: '=?'
			
			template: """

<div class="form-group">

	<label
		data-ng-bind="field.label"
	></label>
	
	<select
		class="form-control"
		name="{{field.name}}"
		
		data-ng-model="field.value"
		data-ng-required="field.required"
		data-ng-options="{{field.options}}"
	></select>

</div>

"""
				
	]

	assignToElement = (element, value) ->
		
		element.find("option[value=\"#{value}\"]").prop 'selected', true

	# ## Implements hook `formWidgets`
	registrar.registerHook 'formWidgets', ->
		
		widgets = []
		
		widgets.push
			
			type: 'select'
			assignToElement: assignToElement
			directive: 'shrub-form-widget-select'
			
		widgets
