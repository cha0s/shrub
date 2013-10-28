$module.directive 'shrubForm', [
	'$compile', '$q', 'forms', 'require'
	($compile, $q, forms, require) ->
		
		link: (scope, element, attrs, controller) ->
			
			formName = "form-#{attrs['shrubForm']}"
			
			$form = angular.element '<form>'
			$form.attr 'ng-controller', formName
			
			# Hacking out the scope, gotta be a nicer way to do this.
			$compile($form) scope
			{form} = $form.scope()
			return unless form?
			
			$form = angular.element '<form>'
			$form.attr 'ng-controller', formName
			
			# Build the form fields.
			for name, field of form
				continue unless field.type?
				
				$wrapper = angular.element '<div>'
				$wrapper.append $field = switch field.type
					
					when 'email', 'password', 'text'
						$wrapper.append(
							angular.element('<label>').text field.title
						) if field.title?
						
						$input = angular.element(
							'<input type="' + field.type + '">'
						).attr(
							name: name
							'data-ng-model': name
						)
						
						$input.attr 'required', 'required' if field.required
						
					when 'submit'
					
						$input = angular.element(
							'<input type="submit">'
						)
						$input.attr 'value', field.title ? "Submit"
						$input.addClass 'btn'
						
				$form.append $wrapper
			
			# Class.
			$form.addClass formName
			
			# Set submit handler, if any
			$form.attr 'data-ng-submit', 'form.submit.handler()'
			
			# Default method to POST.
			$form.attr 'method', 'POST' unless $form.attr 'method'
			
			# Add hidden form key to allow server-side interception/processing.
			$formKeyElement = angular.element '<input type="hidden" />'
			$formKeyElement.attr name: 'formKey', value: attrs['shrubForm']
			$form.append $formKeyElement
			
			# Compile the built form.
			element.append $form
			$compile($form) scope
			
			# Create the form in the system.
			forms.create(
				attrs['shrubForm']
				{form} = $form.scope()
				element.find 'form'
			)
			
			# Guarantee a submit handler.
			(form.submit ?= {}).handler ?= -> $q.when true
			
]

