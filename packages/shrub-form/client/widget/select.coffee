
_ = require 'underscore'

exports.pkgmanRegister = (registrar) ->
	
	# ## Implements hook `formWidgets`
	registrar.registerHook 'formWidgets', ->
		
		widgets = []
		
		widgets.push
			
			type: 'select'
			injected: [
				'key', 'name', 'field', 'form', 'scope'
				(key, name, field, form, scope) ->
					
					$select = $('<select>')

					for optionKey, optionValueOrSpec of field.options
						
						# Options can be a flat string or an object.
						if _.isString optionValueOrSpec
							spec = value: optionValueOrSpec
						else
							spec = optionValueOrSpec
						
						# Create the option tag.
						$option = $('<option>').attr 'value', optionKey
						$option.prop 'disabled', true if spec.disabled
						$option.html spec.value
						
						$select.append $option
						
					# Select attributes.
					$select.prop 'disabled', true if field.disabled
					$select.prop 'multiple', true if field.multiple
					$select.attr 'name', name
					$select.prop 'required', true if field.required
					$select.attr 'size', field.size if field.size?
					
					optionKeys = Object.keys field.options
					if -1 isnt optionKeys.indexOf field.defaultValue
						$select.prop 'selectedIndex', true
					
					$select
			
			]
			
		widgets
