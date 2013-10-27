$module.directive 'shrubForm', [
	'forms'
	(forms) ->
		
		controller: [
			'$attrs', '$element', '$scope'
			(attrs, element, scope) ->
				
				# Create the form in the system.
				forms.create attrs['shrubForm'], scope, element
		]
		
		link: (scope, element, attrs) ->
			
			# Manipulate the form:
			$form = element.find 'form'
			
			# Default method to POST.
			$form.attr 'method', 'POST' unless $form.attr 'method'
			
			# Add hidden form key to allow server-side interception/processing.
			$formKeyElement = angular.element '<input type="hidden" />'
			$formKeyElement.attr(
				name: 'formKey'
				value: attrs['shrubForm']
			)
			$form.append $formKeyElement
			
]

