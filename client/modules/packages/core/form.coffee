
exports.$directive = [
	'$compile', '$injector', '$q', 'core/form', 'require'
	($compile, $injector, $q, form, require) ->
		
		link: (scope, element, attrs) ->
			
			formKey = attrs['coreForm']
			return unless (formSpec = scope[formKey])?
			
			# Hacking out the scope, gotta be a nicer way to do this.
			$form = angular.element '<form>'
			
			# Create the form element.
			$form = angular.element(
				'<form>'
			).attr(
				
				# Set submit handler, if any
				'data-ng-submit': "#{formKey}.submit.handler()"
				
				# Default method to POST.
				method: $form.attr('method') ? 'POST'
			
			).addClass formKey
			
			# Build the form fields.
			for name, field of formSpec
				continue unless field.type?
				
				$wrapper = angular.element '<div>'
				$wrapper.append $field = switch field.type
					
					when 'email', 'password', 'text'
						$wrapper.append(
							angular.element('<label>').text field.label
						) if field.label?
						
						$input = angular.element(
							'<input type="' + field.type + '">'
						).attr(
							name: name
							'data-ng-model': name
						)
						
						if field.defaultValue?
							$input.attr 'value', field.defaultValue
						
						$input.attr 'required', 'required' if field.required
						
						$input
						
					when 'submit'
					
						if field.rpc?
							field.handler ?= ->
							handler = field.handler
							field.handler = ->
								
								i8n = require 'inflection'

								dottedFormKey = i8n.underscore formKey
								dottedFormKey = i8n.dasherize dottedFormKey.toLowerCase()
								dottedFormKey = dottedFormKey.replace '-', '.'
								
								fields = {}
								for name, field of formSpec
									continue if field.type is 'submit'
									fields[name] = scope[name]
								
								$injector.invoke [
									'comm/rpc'
									(rpc) ->
										
										rpc.call(
											dottedFormKey
											fields
										).then(
											(result) -> handler null, result
											(error) -> handler error
										)
								]
								
						$input = angular.element(
							'<input type="submit">'
						)
						$input.attr 'value', field.label ? "Submit"
						$input.addClass 'btn'
						
				$form.append $wrapper
			
			# Add hidden form key to allow server-side interception/processing.
			$formKeyElement = angular.element '<input type="hidden"/>'
			$formKeyElement.attr name: 'formKey', value: formKey
			$form.append $formKeyElement
			
			# Insert and compile the form element.
			element.append $form
			$compile($form) scope
			
			# Register the form in the system.
			form.register formKey, scope, $form
			
			# Guarantee a submit handler.
			(formSpec.submit ?= {}).handler ?= -> $q.when true
			
]

exports.$service = [
	
	->
		
		forms = {}
		
		@register = (key, scope, element) ->
			forms[key] =
				scope: scope
				element: element
					
		@lookup = (key) -> forms[key]
		
		return

]

