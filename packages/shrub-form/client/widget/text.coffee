
exports.pkgmanRegister = (registrar) ->
	
	injectedText = [
		'name', 'field', 'wrapper'
		(name, field, wrapper) ->
			
			wrapper.append(
				angular.element('<label>').text field.label
			) if field.label?
			
			$input = angular.element '<input type="' + field.type + '">'
			
			$input.attr name: name, 'data-ng-model': name
			$input.attr 'required', 'required' if field.required

			$input.addClass 'form-control'
			
			if field.defaultValue?
				$input.attr 'value', field.defaultValue
			
			$input
			
	]

	# ## Implements hook `formWidgets`
	registrar.registerHook 'formWidgets', ->
		
		widgets = []
		
		widgets.push
			
			type: 'email'
			injected: injectedText
			
		widgets.push
			
			type: 'password'
			injected: injectedText
			
		widgets.push
			
			type: 'text'
			injected: injectedText
			
		widgets
