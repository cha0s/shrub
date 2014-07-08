
# # Form
# 
# Define a directive for Angular forms, and a service to cache and look them
# up later.

# ## Implements hook `directive`
exports.$directive = -> [
	'$compile', '$injector', '$q', 'shrub-form', 'shrub-require'
	($compile, {invoke}, $q, {cache}, require) ->
		
		link: (scope, element, attrs) ->
			return unless (formSpec = scope[formKey = attrs.form])?
			
			# Create the form element.
			$form = angular.element(
				'<form>'
			).attr(
				
				# Set submit handler, if any
				'data-ng-submit': "#{formKey}.submit.handler()"
				
				# Default method to POST.
				method: attrs.method ? 'POST'
			
			).addClass formKey
			
			# Build the form fields.
			# `TODO`: Form field types should be defined by hook.
			for name, field of formSpec
				continue unless field.type?
				
				$wrapper = angular.element '<div class="form-group">'
				$wrapper.append $field = switch field.type
					
					when 'hidden'
						
						scope[name] = field.value
						
						angular.element(
							'<input type="hidden">'
						).attr(
							name: name
						)
						
					when 'email', 'password', 'text'
						$wrapper.append(
							angular.element('<label>').text field.label
						) if field.label?
						
						$input = angular.element(
							'<input type="' + field.type + '">'
						).attr(
							name: name
							'data-ng-model': name
						).addClass(
							'form-control'
						)
						
						if field.defaultValue?
							$input.attr 'value', field.defaultValue
						
						$input.attr 'required', 'required' if field.required
						
						$input
						
					when 'submit'
						
						# Handle RPC calls.
						# `TODO`: This should be middleware'd, `rpc` should be
						# implementing it.
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
								
								invoke [
									'rpc'
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
						$input.addClass 'btn btn-default'
						
				$form.append $wrapper
			
			# Add hidden form key to allow server-side interception/processing.
			$formKeyElement = angular.element '<input type="hidden"/>'
			$formKeyElement.attr name: 'formKey', value: formKey
			$form.append $formKeyElement
			
			# Insert and compile the form element.
			element.append $form
			$compile($form) scope
			
			# Register the form in the system.
			cache formKey, scope, $form
			
			# Guarantee a submit handler.
			(formSpec.submit ?= {}).handler ?= -> $q.when true
			
]

# ## Implements hook `service`
exports.$service = -> [
	
	->
		
		service = forms: {}
		
		# ## form.cache
		# 
		# Cache a form for later lookup.
		# 
		# * (string) `key` - The form key.
		# 
		# * (Scope) `scope` - The form's Angular scope.
		# 
		# * (Element) `element` - The form's jqLite element.
		service.cache = (key, scope, element) ->
			service.forms[key] = scope: scope, element: element
					
		service

]

