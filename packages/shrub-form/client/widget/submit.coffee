
exports.pkgmanRegister = (registrar) ->
	
	# ## Implements hook `formWidgets`
	registrar.registerHook 'formWidgets', ->
		
		widgets = []
		
		widgets.push
			
			type: 'submit'
			injected: [
				'key', 'name', 'field', 'form', 'scope'
				(key, name, field, form, scope) ->
				
					$input = angular.element '<input type="submit" />'
					$input.attr 'name', name
					$input.attr 'value', field.label ? "Submit"
					$input.addClass 'btn btn-default'
			
			]
			
		widgets
